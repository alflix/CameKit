Pod::Spec.new do |s|
	s.name                  = 'CameKit'
	s.version               = '0.9.0'
	s.summary               = 'Camera Kit'

	s.homepage              = 'https://www.ganguotech.com/'
	s.license               = { :type => "Copyright", :text => "Copyright 2019" }
	s.authors               = { 'John' => 'john@ganguo.hk' }
	s.source                = { :path => 'Source' }	
	s.ios.framework         = 'UIKit'
	
	s.swift_version         = "5.1"
	s.ios.deployment_target = "10.0"
	s.platform              = :ios, '10.0'
	
	s.module_name           = 'CameKit'
	s.requires_arc          = true
	s.source_files          = 'Source/**/*.swift'
	s.resources             = 'Resources/**/*'

end
