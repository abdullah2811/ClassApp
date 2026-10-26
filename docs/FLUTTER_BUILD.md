# Android release build

This checkout currently contains Dart sources but not an Android runner
directory. Generate the runner once with `flutter create .` in a controlled
branch, then configure the release signing values through Gradle properties or
environment variables.

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
```

Create a private upload keystore with `keytool`, store it outside Git, and
reference it from `android/key.properties` excluded by `.gitignore`.
