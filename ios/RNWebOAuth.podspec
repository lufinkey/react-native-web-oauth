
Pod::Spec.new do |s|
  s.name         = "RNWebOAuth"
  s.version      = "1.0.0"
  s.summary      = "RNWebOAuth"
  s.description  = <<-DESC
                  RNWebOAuth
                   DESC
  s.homepage     = ""
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "luisfinke@gmail.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/lufinkey/react-native-web-oauth.git", :tag => "master" }
  s.source_files  = "RNWebOAuth/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end

  
