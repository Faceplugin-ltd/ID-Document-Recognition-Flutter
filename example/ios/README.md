# iOS example host

Requirements: **Flutter 3.44+** (3.47+ recommended), **macOS + Xcode 15+**, **iOS 15+** device preferred.

The Xcode host project is already in this folder. After placing `docsdk.framework`:

1. Copy `docsdk.framework` → `../ios/Frameworks/docsdk.framework`
2. From repo root: `dart run tool/bootstrap.dart` (creates `docsdk.xcframework`) — or let `pod install` do it
3. `cd ios && pod install`
4. Open `Runner.xcworkspace` and set **your** Team / signing (none is committed)
5. Bundle id must remain `com.faceplugin.documentreader.app` for the demo license

> Only if this `ios/` tree is missing: `cd example && flutter create --platforms=ios --org com.faceplugin.documentreader .`

The Runner target includes a **Sign nested dcrcore** build phase (kept last by the Podfile `post_install`). It runs `"${SRCROOT}/scripts/sign_nested_docsdk.sh"` **after** `[CP] Embed Pods Frameworks` so nested `dcrcore.framework` is re-sealed with your app identity. If launch fails with `code signature invalid` on `dcrcore`, check that phase order in Xcode → Runner → Build Phases.

Camera / photos: `Podfile` `post_install` sets `PERMISSION_CAMERA=1` and `PERMISSION_PHOTOS=1` for `permission_handler`. `Info.plist` already has `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription`. After changing the Podfile, run `cd ios && pod install` (or `flutter run`, which does). If iOS previously denied the prompt, reset it under **Settings → DocumentReader → Camera**.

This plugin supports **Swift Package Manager** (`ios/document_reader_sdk/Package.swift`) and CocoaPods. The example disables SPM because the checkout folder name differs from the package name.
