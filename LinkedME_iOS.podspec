#
# Be sure to run `pod lib lint LinkedME_iOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LinkedME_iOS'
  s.version          = '1.5.4.5'
  s.summary          = 'A short description of LinkedME_LinkPage.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/<GITHUB_USERNAME>/LinkedME_iOS'
  
  #s.xcconfig         = {'BITCODE_GENERATION_MODE' => 'bitcode'}
  s.xcconfig         = {'ENABLE_BITCODE' => 'YES',
                        'OTHER_CFLAGS' => '-fembed-bitcode'}
  
  
  s.license          = { :type => 'MIT', :file => 'LICENSE' }

  s.author           = { 'Bindx' => '487479@gmail.com' }

  s.source           = { :git => 'https://github.com/WFC-LinkedME/LinkedME-iOS-Deep-Linking-SDK', :tag => s.version }

  s.ios.deployment_target = '6.0'

  s.source_files = 'LinkedME_iOS/Classes/*.*','LinkedME_iOS/Classes/Public/*.*'

  s.public_header_files = 'LinkedME_iOS/Classes/Public/*.h'
  
  #  s.pod_target_xcconfig = {  }

  s.frameworks = 'UIKit', 'CoreGraphics', 'CoreTelephony', 'Security', 'SystemConfiguration', 'WebKit','CoreLocation'

end
