package studio.lunabee.nouveaurecit.ui.profile.edit

import studio.lunabee.nouveaurecit.data.user.Coordinates

/** A place the search found: its name as the geocoder writes it, and where it is. */
data class FoundPlace(val name: String, val coordinates: Coordinates)
