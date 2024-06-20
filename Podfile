platform :ios, '12.0'

# Core app dependecies.
def core
  pod 'CocoaLumberjack/Swift', '3.8.2'
  pod 'RxSwift', '6.6.0'
  pod 'RxCocoa', '6.6.0'
  pod 'RxDataSources', '5.0.0'
  pod "RxRealm"
  pod 'Swinject'
  pod 'RxBlocking', '6.6.0'
end

# Realm database.
def realm
  pod 'Realm', '10.33.0'
  pod 'RealmSwift', '10.33.0'
end

# Main App container dependencies.
target 'Windscribe' do
  use_frameworks!
  pod 'IQKeyboardManagerSwift', '6.5.0'
  pod 'ExpyTableView', '1.1'
  pod 'SwipeCellKit', '2.5.4'
  pod "JNKeychain"
  pod "RxGesture", '4.0.4'
  core
  realm
end

# Apps tests.
target 'WindscribeTests' do
  inherit! :search_paths
  use_frameworks!
  pod 'MockingbirdFramework', '~> 0.20'
  core
  realm
end

# Wireguard network extension.
target 'WireGuardTunnel' do
  use_frameworks!
  pod "JNKeychain"
  pod 'Alamofire', '~> 4.0'
  core
  realm
end

# OpenVPN network extension
target 'PacketTunnel' do
  use_frameworks!
  pod 'OpenVPNAdapter', :git => 'https://github.com/ss-abramchuk/OpenVPNAdapter.git', :tag => '0.8.0'
  core
end

# Home widget extension
target 'HomeWidgetExtension' do
  use_frameworks!
  core
end

# SiriIntents extension.
target 'SiriIntents' do
  use_frameworks!
  core
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
