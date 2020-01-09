Pod::Spec.new do |s|
	s.name                  = 'CameKit'
	s.version               = '0.9.0'
	s.summary               = 'Camera Kit'

	s.homepage              = 'https://github.com/alflix/CameKit'
	s.license               = { :type => 'Apache-2.0', :file => 'LICENSE' }
	
	s.authors               = { 'John' => 'jieyuanz24@gmail.com' }
	s.source                = { :git => 'https://github.com/alflix/CameKit.git', :tag => "#{s.version}" }
	s.ios.framework         = 'UIKit'
	
	s.swift_version         = "5.1"
	s.ios.deployment_target = "10.0"
	s.platform              = :ios, '10.0'
	
	s.module_name           = 'CameKit'
	s.requires_arc          = true
	s.source_files          = 'Source/**/*.swift'
	s.resources             = 'Resources/**/*'

end
