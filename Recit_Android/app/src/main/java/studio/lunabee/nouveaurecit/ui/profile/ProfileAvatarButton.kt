package studio.lunabee.nouveaurecit.ui.profile

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import studio.lunabee.nouveaurecit.R
import studio.lunabee.nouveaurecit.data.db.UserEntity
import studio.lunabee.nouveaurecit.designsystem.RecitTheme
import studio.lunabee.nouveaurecit.ui.common.LocalAppContainer
import studio.lunabee.nouveaurecit.ui.navigation.LocalTabRouter
import studio.lunabee.nouveaurecit.ui.navigation.TabRouter

/**
 * `ProfileToolbarItem` (feature 0038): the round button at the top left of Inventaire, Listes and
 * Réseau that opens the profile sheet. The account's picture when it has one, the old Profil tab's
 * icon otherwise — and the icon under the picture too, so a picture loading slowly, or failing,
 * leaves the icon rather than an empty hole.
 */
@Composable
fun ProfileAvatarButton() {
    val router: TabRouter = LocalTabRouter.current
    val myUser: UserEntity? by LocalAppContainer.current.users.myUser.collectAsState(initial = null)
    IconButton(onClick = router::openProfile) {
        Box(contentAlignment = Alignment.Center) {
            Icon(
                imageVector = Icons.Outlined.Person,
                contentDescription = stringResource(R.string.nav_profile),
                tint = RecitTheme.colors.foregroundTinted,
            )
            myUser?.avatarUrl?.let { url ->
                AsyncImage(
                    model = url,
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.size(AVATAR_SIZE).clip(CircleShape),
                )
            }
        }
    }
}

/** As wide as an icon button's touch target allows, inside its 48 dp. */
private val AVATAR_SIZE = 36.dp
