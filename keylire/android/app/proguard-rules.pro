# google_mlkit_text_recognition supports optional script-specific recognizers.
# Keylire ships the Latin recognizer only, so those optional classes are absent.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# ONNX Runtime JNI bindings
-keep class ai.onnxruntime.** { *; }

# SQLite3 Flutter Libs
-keep class org.sqlite.** { *; }

# Kotlin bridges called by name from Dart
-keep class com.keylire.app.** { *; }

# home_widget background receiver and actions
-keep class es.antonborries.home_widget.** { *; }

# flutter_local_notifications serialises via Gson
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keepattributes *Annotation*

# Plugins with native activity / file / auth callbacks
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }
