# Основы Cocoapods 02: Как создать публичную библиотеку
# https://youtu.be/wUjGImmGsVc

Pod::Spec.new do |s|
    s.name = 'PMUserPrinter'
    s.version = '1.0.0'
    s.license = 'MIT'
    s.summary = 'Test framework'
    s.homepage = 'https://github.com/denandreychuk/PMUserPrinter'
    s.authors = { 'Den Andreychuk' => 'business@denandreychuk.com' }
    
    s.source = { :git => 'https://github.com/denandreychuk/PMUserPrinter.git', :tag => s.version.to_s }
    s.source_files = 'Sources/*.swift'
    s.swift_version = '5.0'
    s.platform = :ios, '13.0'
  
    s.dependency 'SwiftyBeaver'
  
  end