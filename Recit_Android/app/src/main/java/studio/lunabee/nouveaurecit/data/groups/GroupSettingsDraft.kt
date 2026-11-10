package studio.lunabee.nouveaurecit.data.groups

/**
 * `GroupSettingsDraft`: the texts and the photo « Réglages du groupe » holds until it is left. The
 * switches are written the moment they move, and are not part of it.
 */
data class GroupSettingsDraft(
    val name: String,
    val description: String,
    val picture: GroupPictureEdit,
) {
    /** Whether « Enregistrer » is offered on [group]: something changed, and the name is one the server takes. */
    fun canSave(group: ReaderGroup): Boolean {
        val changed: Boolean = name != group.name || description != group.description || picture.isChange(from = group.pictureUrl)
        return changed && GroupNameRule.accepts(name)
    }

    /** What leaving by [exit] sends for [group]: on « Enregistrer », each trimmed text that changed and the photo if it did; else nothing. */
    fun writes(exit: GroupSettingsExit, group: ReaderGroup): GroupSettingsWrites = when (exit) {
        GroupSettingsExit.Dismiss -> GroupSettingsWrites.None
        GroupSettingsExit.Save -> GroupSettingsWrites(
            settings = listOfNotNull(
                name.trim().takeIf { it != group.name }?.let(GroupSetting::Name),
                description.trim().takeIf { it != group.description }?.let(GroupSetting::Description),
            ),
            picture = picture.takeIf { it.isChange(from = group.pictureUrl) } ?: GroupPictureEdit.Unchanged,
        )
    }
}
