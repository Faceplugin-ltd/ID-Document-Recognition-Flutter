# iOS DocumentReader runtime

Drop `docsdk.framework` here (unzip from the iOS Google Drive pack).

```text
ios/Frameworks/docsdk.framework/
```

Then on **macOS** generate the SwiftPM binary (CocoaPods can use either):

```bash
dart run tool/bootstrap.dart
# or: cd example/ios && pod install
# → ios/Frameworks/docsdk.xcframework
```

Windows machines only need the Android AAR for `flutter run`; iOS packaging requires a Mac.

The engine ships inside the framework (`Frameworks/dcrcore.framework`). Without these folders, iOS builds fail with missing `docsdk`.
