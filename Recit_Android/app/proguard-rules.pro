# R8 rules for the release build, on top of proguard-android-optimize.txt and the consumer rules
# every library ships (kotlinx.serialization, Room, OkHttp, Coil, CameraX, ML Kit, Navigation 3).
#
# A rule goes here only for a break seen in the minified build, with a comment saying why.
# Never keep the app's own packages wholesale: obfuscation would fall back to 0 %.

# ML Kit's MlKitInitProvider instantiates its ComponentRegistrar classes by reflection, through
# their no-argument constructor. firebase-components keeps the classes but not that constructor,
# which R8's full mode then strips: at launch ComponentDiscovery logs "Could not instantiate
# com.google.mlkit.vision.barcode.internal.BarcodeRegistrar" (NoSuchMethodException <init>), and
# the barcode scanner is left without its components.
-keepclassmembers class * implements com.google.firebase.components.ComponentRegistrar {
    <init>();
}
