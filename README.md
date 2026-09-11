# Scooply mobile

Flutter owner app for Scooply, the POS for ice cream shops.

```bash
cd mobile
flutter pub get
cp oauth.defines.json.example oauth.defines.json
cp ios/Flutter/FacebookSecrets.xcconfig.example ios/Flutter/FacebookSecrets.xcconfig
# Put your Facebook App ID and Client Token in those local files (do not commit them).
flutter run --dart-define-from-file=oauth.defines.json
flutter build apk --release --dart-define-from-file=oauth.defines.json
```
