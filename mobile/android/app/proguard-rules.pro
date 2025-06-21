# ✅ Keep all Stripe classes (PaymentSheet, PaymentIntent, etc.)
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# ✅ Keep required OkHttp and Retrofit classes (Stripe uses them internally)
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

-keep class retrofit2.** { *; }
-dontwarn retrofit2.**