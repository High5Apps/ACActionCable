#
# Be sure to run `pod lib lint ACActionCable.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |spec|
  spec.name                  = 'ACActionCable'
  spec.version               = '0.4.0'
  spec.license               = { :type => 'MIT', :file => 'LICENSE' }
  spec.homepage              = 'https://github.com/High5Apps/ACActionCable'
  spec.authors               = { 'Julian Tigler' => 'high5apps@gmail.com' }
  spec.summary               = 'An Action Cable client for Rails 6'
  spec.source                = { :git => 'https://github.com/High5Apps/ACActionCable.git', :tag => 'v0.4.0' }
  spec.swift_version         = '5.1'
  spec.ios.deployment_target = '11.0'
  spec.source_files          = 'Sources/**/*'
  spec.frameworks            = 'Foundation'
end
