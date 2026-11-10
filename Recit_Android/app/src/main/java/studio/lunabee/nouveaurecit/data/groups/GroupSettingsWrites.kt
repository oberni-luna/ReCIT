package studio.lunabee.nouveaurecit.data.groups

/** What leaving « Réglages du groupe » sends: one `update-settings` per text in [settings], and [picture]. */
data class GroupSettingsWrites(
    val settings: List<GroupSetting>,
    val picture: GroupPictureEdit,
) {
    companion object {
        val None: GroupSettingsWrites = GroupSettingsWrites(settings = emptyList(), picture = GroupPictureEdit.Unchanged)
    }
}
