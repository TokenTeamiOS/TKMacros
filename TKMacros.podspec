Pod::Spec.new do |s|
  s.name             = 'TKMacros'
  s.version          = '0.0.1'
  s.summary          = 'TK Macros'
  s.homepage         = 'https://github.com/TokenTeamiOS/TKMacros'
  s.license          = 'Proprietary'
  s.author           = { 'TokenTeam' => 'tokenteamios@163.com' }
  s.source           = { :git => 'git@github.com:TokenTeamiOS/TKMacros.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.9'

  # Source files for the library part (The macro definition and types)
  s.source_files = 'Sources/TKMacros/**/*.swift'

  # Preserve the pre-built macro binary so it is copied to the Pods directory
  s.preserve_paths = 'Prebuilt/TKMacrosExecutable','Scripts/tk_swift_flags.rb'

  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-load-plugin-executable ${PODS_ROOT}/TKMacros/Prebuilt/TKMacrosExecutable#TKMacrosExecutable'
  }
  s.user_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => '-load-plugin-executable ${PODS_ROOT}/TKMacros/Prebuilt/TKMacrosExecutable#TKMacrosExecutable -enable-experimental-feature SymbolLinkageMarkers'
  }
end
