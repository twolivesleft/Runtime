# Codea Runtime for Android

The Maven repository Codea's Android exports build against, served at
https://twolivesleft.github.io/Runtime/maven. It is published by CI; don't edit it by hand.

```kotlin
repositories { maven { url = uri("https://twolivesleft.github.io/Runtime/maven") } }
dependencies { implementation("com.twolivesleft:codea-runtime:3.19.+") }
```

The iOS runtime is the Swift package on this repository's `main` branch.
