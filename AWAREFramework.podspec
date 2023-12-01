#
# Be sure to run `pod lib lint AWAREFramework.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AWAREFramework'
  s.version          = '1.14.8'
  s.summary          = 'AWARE: An Open-source Context Instrumentation Framework'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  AWARE is an Android and iOS framework dedicated to instrument, infer, log and share mobile context information, for application developers, researchers and smartphone users. AWARE captures hardware-, software-, and human-based data. They transform data into information you can understand.
                       DESC

  s.homepage         = 'https://github.com/tetujin/AWAREFramework-iOS'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Apache2', :file => 'LICENSE' }
  s.author           = { 'Yuuki Nishiyama' => 'yuukin@iis.u-tokyo.ac.jp' }
  s.source           = { :git => 'https://github.com/tetujin/AWAREFramework-iOS.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'
#  s.pod_target_xcconfig = {
#    'IPHONEOS_DEPLOYMENT_TARGET' => '11.0'
#  }
#  
#  s.pod_target_xcconfig = {
#      'SWIFT_VERSION' => '5.0',
#      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64',
#  }
#  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
#  s.swift_version = '5.0'
#  s.pod_target_xcconfig  = {'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) COCOAPODS=1'}
  
#  VALID_ARCHS
  
  plugin_path = 'AWAREFramework/Classes/Plugins/'
  
  s.subspec 'HealthKit' do |sp|
    sp.source_files = [plugin_path+'HealthKit/**/*.m',plugin_path+'HealthKit/**/*.h']
    sp.frameworks = 'HealthKit'
    sp.pod_target_xcconfig  = {'GCC_PREPROCESSOR_DEFINITIONS' => 'IMPORT_HEALTHKIT=1'}
    sp.dependency 'AWAREFramework/Core'
  end

  s.subspec 'Bluetooth' do |sp|
    sp.source_files = [plugin_path+'Bluetooth/**/*.m',plugin_path+'Bluetooth/**/*.h',plugin_path+'BLEHeartRate/**/*.h',plugin_path+'BLEHeartRate/**/*.m']
    sp.frameworks = 'CoreBluetooth'
    sp.dependency 'AWAREFramework/Core'
    sp.pod_target_xcconfig  = {'GCC_PREPROCESSOR_DEFINITIONS' => 'IMPORT_BLUETOOTH=1'}
  end

  s.subspec 'Calendar' do |sp|
    sp.source_files = [plugin_path+'Calendar/**/*.m',plugin_path+'Calendar/**/*.h',plugin_path+'CalendarESMScheduler/**/*.h',plugin_path+'CalendarESMScheduler/**/*.m']
    sp.frameworks = 'EventKit', 'EventKitUI'
    sp.pod_target_xcconfig  = {'GCC_PREPROCESSOR_DEFINITIONS' => 'IMPORT_CALENDAR=1'}
    sp.dependency 'AWAREFramework/Core'
  end

  s.subspec 'Contact' do |sp|
    sp.source_files = [plugin_path+'Contacts/**/*.m',plugin_path+'Contacts/**/*.h']
    sp.pod_target_xcconfig  = {'GCC_PREPROCESSOR_DEFINITIONS' => 'IMPORT_CONTACT=1'}
    sp.dependency 'AWAREFramework/Core'
  end

  s.subspec 'Microphone' do |sp|
    sp.source_files = [plugin_path+'AmbientNoise/**/*.m',plugin_path+'AmbientNoise/**/*.h',plugin_path+'Conversation/**/*.m',plugin_path+'Conversation/**/*.h']
    sp.ios.vendored_frameworks = 'AWAREFramework/Frameworks/StudentLifeAudio.framework'
    sp.pod_target_xcconfig  = {'GCC_PREPROCESSOR_DEFINITIONS' => 'IMPORT_MIC=1'}
    sp.dependency 'AWAREFramework/Core'
  end

  s.subspec 'MotionActivity' do |sp|
    sp.source_files = [plugin_path+'IOSActivityRecognition/**/*.m',plugin_path+'IOSActivityRecognition/**/*.h',plugin_path+'Pedometer/**/*.h',plugin_path+'Pedometer/**/*.m',plugin_path+'HeadphoneMotion/**/*.h',plugin_path+'HeadphoneMotion/**/*.m']
    #sp.pod_target_xcconfig  = { 'OTHER_LDFLAGS' => 'IMPORT_MOTION_ACTIVITY=1' }
    sp.pod_target_xcconfig  = {'GCC_PREPROCESSOR_DEFINITIONS' => 'IMPORT_MOTION_ACTIVITY=1'}
    sp.dependency 'AWAREFramework/Core'
  end
 
  s.subspec 'Core' do |cs|
      cs.source_files = ['AWAREFramework/Classes/Core/**/*.m','AWAREFramework/Classes/Core/**/*.h','AWAREFramework/Classes/**/*.swift','AWAREFramework/Classes/Sensors/**/*.m','AWAREFramework/Classes/Sensors/**/*.h','AWAREFramework/Classes/ESM/**/*.h','AWAREFramework/Classes/ESM/**/*.m']
      cs.resources = 'AWAREFramework/Assets/**/*.xcdatamodeld','AWAREFramework/Classes/**/*.xcdatamodeld'
      cs.resource_bundles = {
       'AWAREFramework' => ['AWAREFramework/Assets/**/*.png','AWAREFramework/Assets/*.xib','AWAREFramework/Assets/**/*.jpg','AWAREFramework/Assets/**/*.mp3', 'AWAREFramework/Assets/**/*.xcdatamodeld','AWAREFramework/Assets/**/*.xcassets','AWAREFramework/Classes/**/*.xcdatamodeld']
      }
      cs.frameworks = 'UIKit', 'MapKit', 'CoreData', 'CoreTelephony', 'CoreLocation', 'CoreMotion', 'UserNotifications', 'Accelerate', 'AudioToolbox','AVFoundation','GLKit'
#      cs.dependency 'TrueTime', '~> 5.0.3'
#      cs.dependency 'CocoaAsyncSocket'
  end

  s.default_subspec = 'Core'
  
  s.static_framework = true
  
end
