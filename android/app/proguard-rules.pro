# CalcMaster ProGuard rules — keep Flutter + plugin classes intact.
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Provider package state classes
-keep class * extends androidx.lifecycle.ViewModel { *; }

# Suppress noisy warnings from transitive deps
-dontwarn io.flutter.embedding.**

# Play Core is referenced by Flutter's deferred-components support even when
# the app never uses deferred components, and it is not on the classpath. R8
# treats those missing classes as an error and fails the minify task, so the
# release build dies where the debug build is fine — a release-only failure.
-dontwarn com.google.android.play.core.**
