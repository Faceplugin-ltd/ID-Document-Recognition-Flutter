# Vendored SwiftPM binary

`docsdk.xcframework` is generated from `ios/Frameworks/docsdk.framework` by
`dart run tool/bootstrap.dart` or `example/ios` `pod install`, then copied here.

`Package.swift` must reference this in-package path. A relative `../Frameworks`
breaks under Flutter’s ephemeral `Packages/.packages` layout.
