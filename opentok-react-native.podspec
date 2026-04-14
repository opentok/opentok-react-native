require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name          = package['name']
  s.version       = package['version']
  s.summary       = package['description']
  s.license       = package['license']

  s.authors       = package['author']
  s.homepage      = package['homepage']
  s.platform      = :ios, "13.0"
  s.swift_version = "4.2"

  s.source        = { :git => "https://github.com/opentok/opentok-react-native.git", :tag => "v#{s.version}" }
  # This library currently ships the classic architecture iOS implementation.
  # Avoid exporting generated Fabric/C++ headers, which break non-new-architecture builds.
  s.source_files  = "ios/OpenTokReactNative/**/*.{h,m,swift}"

  s.dependency 'React'
  s.dependency 'OTXCFramework','2.31.1'
end
