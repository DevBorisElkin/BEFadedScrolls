Pod::Spec.new do |s|
    s.name = 'BEFadedScrolls'
    s.version = '1.0.7'
    s.license = { :type => "MIT", :file => "LICENSE" }
    #s.license = 'MIT'
    s.summary = 'Simple Faded Scrolls'
    s.homepage = 'https://github.com/DevBorisElkin/BEFadedScrolls'
    s.authors = { 'Boris Elkin' => 'https://github.com/DevBorisElkin' }
    
    s.source = { :git => 'https://github.com/DevBorisElkin/BEFadedScrolls.git', :tag => s.version.to_s }
    s.source_files = 'Sources/*.swift'
    s.swift_version = '5.0'
    s.platform = :ios, '12.0'
  end