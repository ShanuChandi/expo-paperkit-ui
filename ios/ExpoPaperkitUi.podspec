Pod::Spec.new do |s|
  s.name           = 'ExpoPaperkitUi'
  s.version        = '1.0.0'
  s.summary        = 'Expo module for PaperKit integration'
  s.description    = 'Native module providing PaperKit markup functionality for Expo apps'
  s.author         = ''
  s.homepage       = 'https://docs.expo.dev/modules/'
  s.platforms      = { :ios => '26.0' }
  s.source         = { git: '' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  s.frameworks = 'PaperKit', 'PencilKit', 'UIKit'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_COMPILATION_MODE' => 'wholemodule'
  }

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"
end
