
Gem::Specification.new do |s|
  s.name        = "redcar-dev"
  s.version     = "0.12.0dev"
  s.platform    = "java"
  s.authors     = ["Daniel Lucraft"]
  s.email       = ["dan@fluentradical.com"]
  s.homepage    = "http://github.com/danlucraft/redcar"
  s.summary     = "A pure Ruby text editor"
  s.description = ""
 
  s.files        = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md) + 
                     Dir.glob("vendor/jface/*.jar") + Dir.glob("vendor/*.jar")
  s.executables  = []
  s.require_path = 'lib'
end
