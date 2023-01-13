Pod::Spec.new do |spec|
  spec.name        = 'ChartboostHeliumAdapterIronSource'
  spec.version     = '4.7.2.5.1.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/helium-ios-adapter-ironsource'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Helium iOS SDK IronSource adapter.'
  spec.description = 'IronSource Adapters for mediating through Helium. Supported ad formats: Banner, Interstitial, and Rewarded.'

  # Source
  spec.module_name  = 'HeliumAdapterIronSource'
  spec.source       = { :git => 'https://github.com/ChartBoost/helium-ios-adapter-ironsource.git', :tag => '#{spec.version}' }
  spec.source_files = 'Source/**/*.{swift,h,m}'
  
  # Public header to expose this Obj-C IronSource wrapper to Swift.
  spec.public_header_files = 'Source/CHBHIronSourceWrapper.h'

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '10.0'

  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'UIKit']
  
  # This adapter is compatible with all Helium 4.X versions of the SDK.
  spec.dependency 'ChartboostHelium', '~> 4.0'

  # Partner network SDK and version that this adapter is certified to work with.
  spec.dependency 'IronSourceSDK', '7.2.5.1'

  # IronSource SDK currently does not support arm64 simulators.
  spec.pod_target_xcconfig = { 
    'OTHER_LDFLAGS' => '-lObjC',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
  }
  
  # The partner network SDK is a static framework which requires the static_framework option.
  spec.static_framework = true
end
