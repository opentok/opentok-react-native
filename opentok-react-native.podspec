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
  s.source_files  = "ios/**/*.{h,m,swift}"

  s.dependency 'React'
  s.dependency 'OTXCFramework','2.25.1'
end
