Pod::Spec.new do |spec|
  spec.name        = 'ChartboostMediationAdapterIronSource'
  spec.version     = '5.9.5.0.0.0'
  spec.license     = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.homepage    = 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-ironsource'
  spec.authors     = { 'Chartboost' => 'https://www.chartboost.com/' }
  spec.summary     = 'Chartboost Mediation iOS SDK IronSource adapter.'
  spec.description = 'IronSource Adapters for mediating through Chartboost Mediation. Supported ad formats: Banner, Interstitial, and Rewarded.'

  # Source
  spec.module_name  = 'ChartboostMediationAdapterIronSource'
  spec.source       = { :git => 'https://github.com/ChartBoost/chartboost-mediation-ios-adapter-ironsource.git', :tag => spec.version }
  spec.source_files = 'Source/**/*.{swift}'
  spec.resource_bundles = { 'ChartboostMediationAdapterIronSource' => ['PrivacyInfo.xcprivacy'] }

  # Minimum supported versions
  spec.swift_version         = '5.0'
  spec.ios.deployment_target = '13.0'

  # System frameworks used
  spec.ios.frameworks = ['Foundation', 'UIKit']

  # Dependencies
  spec.dependency 'ChartboostMediationSDK', '~> 5.0'
  spec.dependency 'IronSourceSDK', '~> 9.5.0.0'

  spec.static_framework = true
end
