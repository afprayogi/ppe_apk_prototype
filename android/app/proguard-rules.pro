# TensorFlow Lite — jangan strip class yg dipakai via reflection
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-dontwarn org.tensorflow.lite.**

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
