    # Razorpay SDK
    -keep class com.razorpay.** { *; }
    -dontwarn com.razorpay.**
    -keep class proguard.annotation.Keep { *; }
    -keep class proguard.annotation.KeepClassMembers { *; }

# Socket.io Websocket
-keep class io.socket.** { *; }
-dontwarn io.socket.**

# OkHttp (if used internally)
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# Gson (socket sometimes serializes JSON)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
