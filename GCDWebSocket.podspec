# http://guides.cocoapods.org/syntax/podspec.html
# http://guides.cocoapods.org/making/getting-setup-with-trunk.html
# $ sudo gem update cocoapods
# (optional) $ pod trunk register {email} {name} --description={computer}
# $ pod trunk --verbose push
# DELETE THIS SECTION BEFORE PROCEEDING!

Pod::Spec.new do |s|
  s.name     = 'GCDWebSocket'
  s.version  = '0.0.1'
  s.author   =  { 'zhuruhong' => 'zhu410289616@163.com' }
  s.license  = { :type => 'BSD', :file => 'LICENSE' }
  s.homepage = 'https://github.com/zhu410289616/GCDWebSocket'
  s.summary  = 'Lightweight GCD based HTTP server for OS X & iOS (includes web based uploader & WebDAV server)'
  
  s.source   = { :git => 'https://github.com/zhu410289616/GCDWebSocket.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
#  s.tvos.deployment_target = '9.0'
#  s.osx.deployment_target = '10.7'
  s.requires_arc = true
  
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |cs|
    cs.dependency 'GCDWebServer/Core'
    cs.source_files = 'Core/**/*.{h,m}'
    cs.requires_arc = true
  end
  
  s.subspec 'EchoServer' do |cs|
    cs.dependency 'GCDWebSocket/Core'
    cs.source_files = 'EchoServer/**/*.{h,m}'
    cs.requires_arc = true
  end

end
