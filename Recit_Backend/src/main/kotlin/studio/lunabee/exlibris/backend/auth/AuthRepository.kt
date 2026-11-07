package studio.lunabee.exlibris.backend.auth

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jetbrains.exposed.v1.core.Op
import org.jetbrains.exposed.v1.core.ResultRow
import org.jetbrains.exposed.v1.core.and
import org.jetbrains.exposed.v1.core.eq
import org.jetbrains.exposed.v1.core.lowerCase
import org.jetbrains.exposed.v1.core.plus
import org.jetbrains.exposed.v1.core.stringParam
import org.jetbrains.exposed.v1.exceptions.ExposedSQLException
import org.jetbrains.exposed.v1.jdbc.Database
import org.jetbrains.exposed.v1.jdbc.deleteReturning
import org.jetbrains.exposed.v1.jdbc.deleteWhere
import org.jetbrains.exposed.v1.jdbc.insert
import org.jetbrains.exposed.v1.jdbc.selectAll
import org.jetbrains.exposed.v1.jdbc.transactions.transaction
import org.jetbrains.exposed.v1.jdbc.update
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import studio.lunabee.exlibris.backend.db.UserTokensTable
import studio.lunabee.exlibris.backend.db.UsersTable

class AuthRepository(
    private val database: Database,
) {
    suspend fun findById(id: String): Account? = findOne { UsersTable.id eq id }

    /** Without regard to case, as inventaire.io's `byUsername` view, and as the unique index. */
    suspend fun findByUsername(username: String): Account? =
        findOne { UsersTable.username.lowerCase() eq stringParam(username).lowerCase() }

    suspend fun findByEmail(email: String): Account? =
        findOne {
            UsersTable.email.lowerCase() eq
                stringParam(email).lowerCase()
        }

    /** `false` when the username or the address was taken in the meantime: the unique indexes said no. */
    suspend fun insert(
        account: Account,
        created: Long,
    ): Boolean =
        withContext(Dispatchers.IO) {
            try {
                transaction(database) {
                    UsersTable.insert {
                        it[id] = account.id
                        it[version] = 1
                        it[username] = account.username
                        it[email] = account.email
                        it[passwordHash] = account.passwordHash
                        it[language] = account.language
                        it[emailValidated] = account.isEmailValidated
                        it[UsersTable.created] = created
                    }
                }
                true
            } catch (error: ExposedSQLException) {
                if (error.sqlState != UNIQUE_VIOLATION) throw error
                logger.info("Signup lost a race on a unique index: {}", error.message)
                false
            }
        }

    suspend fun updatePasswordHash(
        userId: String,
        hash: String,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) { setPasswordHash(userId, hash) }
        }
    }

    /** Replaces the account's previous link for [purpose], which stops opening. */
    suspend fun replaceToken(
        userId: String,
        purpose: TokenPurpose,
        tokenHash: String,
        expiresAt: Long,
    ) {
        withContext(Dispatchers.IO) {
            transaction(database) {
                UserTokensTable.deleteWhere {
                    (UserTokensTable.userId eq userId) and
                        (UserTokensTable.purpose eq purpose.storedName)
                }
                UserTokensTable.insert {
                    it[UserTokensTable.tokenHash] = tokenHash
                    it[UserTokensTable.userId] = userId
                    it[UserTokensTable.purpose] = purpose.storedName
                    it[UserTokensTable.expiresAt] = expiresAt
                }
            }
        }
    }

    /** The account an unexpired link opens, the link left as it is. */
    suspend fun findTokenAccount(
        tokenHash: String,
        purpose: TokenPurpose,
        now: Long,
    ): Account? =
        withContext(Dispatchers.IO) {
            transaction(database) {
                UserTokensTable
                    .selectAll()
                    .where {
                        (UserTokensTable.tokenHash eq tokenHash) and
                            (UserTokensTable.purpose eq purpose.storedName)
                    }.singleOrNull()
                    ?.takeIf { it[UserTokensTable.expiresAt] > now }
                    ?.let { row -> selectAccount { UsersTable.id eq row[UserTokensTable.userId] } }
            }
        }

    /** Spends the link and marks the address confirmed, at once; `null` when the link opens nothing. */
    suspend fun confirmEmail(
        tokenHash: String,
        now: Long,
    ): Account? =
        withContext(Dispatchers.IO) {
            transaction(database) {
                spendToken(tokenHash, TokenPurpose.EMAIL_CONFIRMATION, now)?.let { userId ->
                    UsersTable.update({ UsersTable.id eq userId }) {
                        it[emailValidated] = true
                        it[version] = version + 1
                    }
                    selectAccount { UsersTable.id eq userId }
                }
            }
        }

    /** Spends the link and sets the password, at once; `null` when the link opens nothing. */
    suspend fun resetPassword(
        tokenHash: String,
        passwordHash: String,
        now: Long,
    ): Account? =
        withContext(Dispatchers.IO) {
            transaction(database) {
                spendToken(tokenHash, TokenPurpose.PASSWORD_RESET, now)?.let { userId ->
                    setPasswordHash(userId, passwordHash)
                    selectAccount { UsersTable.id eq userId }
                }
            }
        }

    private suspend fun findOne(condition: () -> Op<Boolean>): Account? =
        withContext(Dispatchers.IO) {
            transaction(database) { selectAccount(condition) }
        }

    private companion object {
        /** Postgres's `unique_violation`. */
        const val UNIQUE_VIOLATION: String = "23505"

        val logger: Logger = LoggerFactory.getLogger(AuthRepository::class.java)
    }
}

private fun selectAccount(condition: () -> Op<Boolean>): Account? =
    UsersTable
        .selectAll()
        .where(condition)
        .singleOrNull()
        ?.toAccount()

private fun setPasswordHash(
    userId: String,
    hash: String,
) {
    UsersTable.update({ UsersTable.id eq userId }) {
        it[passwordHash] = hash
        it[version] = version + 1
    }
}

/** Deleted whether or not it expired: a link opens once, and an expired one never again. */
private fun spendToken(
    tokenHash: String,
    purpose: TokenPurpose,
    now: Long,
): String? =
    UserTokensTable
        .deleteReturning(listOf(UserTokensTable.userId, UserTokensTable.expiresAt)) {
            (UserTokensTable.tokenHash eq tokenHash) and (UserTokensTable.purpose eq purpose.storedName)
        }.singleOrNull()
        ?.takeIf { it[UserTokensTable.expiresAt] > now }
        ?.get(UserTokensTable.userId)

private fun ResultRow.toAccount(): Account =
    Account(
        id = this[UsersTable.id],
        username = this[UsersTable.username],
        email = this[UsersTable.email],
        passwordHash = this[UsersTable.passwordHash],
        language = this[UsersTable.language],
        isEmailValidated = this[UsersTable.emailValidated],
    )
