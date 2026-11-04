package studio.lunabee.nouveaurecit.ui.common

/** One word of [CapsuleTabs]: what it shows, and what a screen reader says instead (« Inventaire, 540 éléments »). */
data class CapsuleTab(val label: String, val description: String = label)
