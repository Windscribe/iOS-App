is_tvos = false
target_platform = is_tvos ? :tvos : :ios
platform_version = is_tvos ? '17.0' : '15.0'
# Core app dependecies.
def core
  pod 'CocoaLumberjack/Swift', '3.8.2'
  pod 'RxSwift', '6.6.0'
  pod 'RxCocoa', '6.6.0'
  pod 'RxDataSources', '5.0.0'
  pod "RxRealm"
  pod 'Swinject'
  pod 'RxBlocking', '6.6.0'
  pod 'SwiftSoup', '1.7.4'
end
# Realm database.
def realm
  pod 'Realm', '10.33.0'
  pod 'RealmSwift', '10.33.0'
end
# Main App container dependencies.
target 'Windscribe' do
  platform :ios, '15.0'
  use_frameworks!
  pod 'IQKeyboardManagerSwift', '6.5.0'
  pod 'ExpyTableView', '1.1'
  pod 'SwipeCellKit', '2.5.4'
  pod "RxGesture", '4.0.4'
  pod 'SimpleKeychain', '~> 1.0'
  core
  realm
end
# Apps tests.
target 'WindscribeTests' do
  platform :ios, '15.0'
  inherit! :search_paths
  use_frameworks!
  pod 'MockingbirdFramework', '~> 0.20'
  core
  realm
end
# Wireguard network extension.
target 'WireGuardTunnel' do
  platform target_platform, platform_version
  use_frameworks!
  use_modular_headers!
  pod 'SimpleKeychain', '~> 1.0'
  pod 'Alamofire', '~> 4.0'
  core
  realm
end
# OpenVPN network extension
target 'PacketTunnel' do
  platform target_platform, platform_version
  use_modular_headers!
  use_frameworks!
  core
end
# Home widget extension
target 'HomeWidgetExtension' do
  platform :ios, '15.0'
  pod 'SimpleKeychain', '~> 1.0'
  use_frameworks!
  pod 'SimpleKeychain', '~> 1.0'
  core
end
# SiriIntents extension.
target 'SiriIntents' do
 platform :ios, '15.0'
  use_frameworks!
  pod 'SimpleKeychain', '~> 1.0'
  core
end
# TV.
target 'WindscribeTV' do
  platform :tvos, '17.0'
  use_modular_headers!
  use_frameworks!
  pod 'SwiftSoup', '1.7.4'
  core
  realm
  pod 'SimpleKeychain', '~> 1.0'
end
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
