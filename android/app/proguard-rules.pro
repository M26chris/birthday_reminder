# ─────────────────────────────────────────────────────────────────────────────
# Gson / TypeToken — fixes the flutter_local_notifications R8 crash
#
# When a scheduled notification fires, ScheduledNotificationReceiver uses
# Gson's TypeToken internally. R8 strips generic signatures unless told
# otherwise, causing "TypeToken must be created with a type argument" crash.
# ─────────────────────────────────────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ─────────────────────────────────────────────────────────────────────────────
# flutter_local_notifications — keep the alarm receiver and its models
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.dexterous.** { *; }

# ─────────────────────────────────────────────────────────────────────────────
# Preserve source file names and line numbers in crash reports
# ─────────────────────────────────────────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
