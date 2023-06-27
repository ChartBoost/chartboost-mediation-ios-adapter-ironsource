Pod::Spec.new do |spec|
  spec.name        = 'ChartboostMediationAdapterIronSource'
  spec.version     = '4.7.3.1.0.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-ironsource'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Chartboost Mediation iOS SDK IronSource adapter.'
  spec.description = 'IronSource Adapters for mediating through Chartboost Mediation. Supported ad formats: Banner, Interstitial, and Rewarded.'

  # Source
  spec.module_name  = 'ChartboostMediationAdapterIronSource'
  spec.source       = { :git => 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-ironsource.git', :tag => spec.version }
  spec.source_files = 'Source/**/*.{swift,h,m}'

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '10.0'

  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'UIKit']
  
  # This adapter is compatible with all Chartboost Mediation 4.X versions of the SDK.
  spec.dependency 'ChartboostMediationSDK', '~> 4.0'

  # Partner network SDK and version that this adapter is certified to work with.
  spec.dependency 'IronSourceSDK', '~> 7.3.1.0'

  # IronSource SDK does not support i386 simulators.
  spec.pod_target_xcconfig = { 
    'OTHER_LDFLAGS' => '-lObjC',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  
  # The partner network SDK is a static framework which requires the static_framework option.
  spec.static_framework = true
end
