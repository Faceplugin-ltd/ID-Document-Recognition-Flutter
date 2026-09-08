#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'document_reader_sdk'
  s.version          = '0.1.0'
  s.summary          = 'FacePlugin Document Reader SDK for Flutter'
  s.description      = <<-DESC
FacePlugin Document Reader SDK — on-device ID / passport / DL recognition.
                       DESC
  s.homepage         = 'https://faceplugin.com'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'FacePlugin' => 'info@faceplugin.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'document_reader_sdk/Sources/document_reader_sdk/**/*.{h,m}'
  s.public_header_files = 'document_reader_sdk/Sources/document_reader_sdk/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Prefer xcframework (SwiftPM + modern Xcode); fall back to .framework.
  frameworks = []
  xc = File.join(__dir__, 'Frameworks/docsdk.xcframework')
  fw = File.join(__dir__, 'Frameworks/docsdk.framework')
  if File.directory?(xc)
    frameworks << 'Frameworks/docsdk.xcframework'
  elsif File.directory?(fw)
    frameworks << 'Frameworks/docsdk.framework'
  end
  s.vendored_frameworks = frameworks unless frameworks.empty?

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  s.swift_version = '5.0'
end
