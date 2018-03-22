#
# Be sure to run `pod lib lint AWAREFramework.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AWAREFramework'
  s.version          = '0.1.0'
  s.summary          = 'A short description of AWAREFramework.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/tetujin/AWAREFramework-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Apache2', :file => 'LICENSE' }
  s.author           = { 'tetujin' => 'tetujin@ht.sfc.keio.ac.jp' }
  s.source           = { :git => 'https://github.com/tetujin/AWAREFramework-iOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.3'
  
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.2' }

  s.source_files = 'AWAREFramework/Classes/**/*'
  
   s.resource_bundles = {
     'AWAREFramework' => ['AWAREFramework/Assets/**/*.png','AWAREFramework/Assets/*.xib','AWAREFramework/Assets/**/*.jpg', 'AWAREFramework/Assets/**/*.xcdatamodeld']
   }
   
   s.resources = 'AWAREFramework/Assets/**/*.xcdatamodeld'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'MapKit', 'CoreData', 'CoreTelephony', 'CoreLocation', 'CoreMotion', 'CoreBluetooth', 'EventKit', 'EventKitUI'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.static_framework = true
  
  s.dependency 'MQTTKit'
  s.dependency 'SCNetworkReachability'
  s.dependency 'GoogleSignIn'
  s.dependency 'ios-ntp'
  s.dependency 'EZAudio'
  s.dependency 'SVProgressHUD'
  s.dependency 'EAIntroView', '~> 2.9.0'
  # s.dependency 'EstimoteSDK'
  
end
