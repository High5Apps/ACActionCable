#
# Be sure to run `pod lib lint ACActionCable.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |spec|
  spec.name                  = 'ACActionCable'
  spec.version               = '2.1.2'
  spec.license               = { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage              = 'https://github.com/High5Apps/ACActionCable'
  spec.authors               = { 'Julian Tigler' => 'high5apps@gmail.com', 'Fabian Jäger' => 'fabian@mailbutler.io' }
  spec.summary               = 'A well-tested, dependency-free Action Cable client for Rails 6'
  spec.source                = { :git => 'https://github.com/High5Apps/ACActionCable.git', :tag => 'v2.1.2' }
  spec.swift_version         = '5.1'
  spec.ios.deployment_target = '11.0'
  spec.osx.deployment_target  = '10.13'
  spec.source_files          = 'Sources/**/*'
  spec.frameworks            = 'Foundation'
end
