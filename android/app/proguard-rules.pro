# Flutter keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Firebase / Play services (safe defaults)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# AndroidX lifecycle (avoid reflection issues)
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keepclassmembers class * extends androidx.lifecycle.ViewModel { <init>(...); }
