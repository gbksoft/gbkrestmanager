
Pod::Spec.new do |spec|

  spec.name         = "GBKSoftRestManager"
  spec.version      = "0.1.0"
  spec.summary      = "Rest manager"
  spec.license      = "MIT"
  spec.author       = { "Artem Korzh" => "korzh.aa@gbksoft.com" }
  spec.homepage     = "https://gitlab.gbksoft.net/korzh-aa/gbksoftrestmanager"
  spec.source       = { :git => "https://gitlab.gbksoft.net/korzh-aa/gbksoftrestmanager", :tag => "#{spec.version}" }
  spec.ios.deployment_target = "10.0"
  spec.swift_version = "5.1"
  spec.source_files  = "Sources/GBKSoftRestManager/**/*.swift"

end
