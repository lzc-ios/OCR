Pod::Spec.new do |s|

  s.name         = "OCR"
  s.version      = "0.1.1"
  s.summary      = "OCR"

  s.description  = <<-DESC
                   OCR
                   DESC

  s.homepage     = "https://github.com/lzc-ios/OCR"
  s.license      = "MIT"
  s.author             = { "lzc-ios" => "1060494425@qq.com" }
  s.social_media_url   = "http://www.huangyibiao.com/"
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/lzc-ios/OCR", :tag => "v#{s.version}" }
  s.source_files  = "OCRSource/*"
  s.requires_arc = true
 s.dependency "SVProgressHUD"

end
