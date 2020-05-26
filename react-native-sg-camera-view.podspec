require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-sg-camera-view"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                  react-native-sg-camera-view
                   DESC
  s.homepage     = "https://github.com/nvdnvd00/SGCameraView"
  # brief license entry:
  s.license      = "MIT"
  # optional - use expanded license entry instead:
  # s.license    = { :type => "MIT", :file => "LICENSE" }
  s.authors      = { "Duc Nguyen" => "nvdnvd00@email.com" }
  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/nvdnvd00/SGCameraView.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,c,m,swift,xcassets}"
  s.requires_arc = true

  s.dependency "React"
  # ...
  # s.dependency "..."
end

