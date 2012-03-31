
Gem::Specification.new do |s|
  s.name        = "redcar-javamateview"
  s.version     = "0.3"
  s.platform    = "ruby"
  s.authors     = ["Daniel Lucraft"]
  s.email       = ["dan@fluentradical.com"]
  s.homepage    = "http://github.com/danlucraft/redcar-javamateview"
  s.summary     = "A source editing widget for SWT that understands Textmate syntaxes and themes"
  s.description = ""
 
  s.files        = Dir.glob("lib/javamateview/**/*") + %w(LICENSE README Rakefile lib/javamateview.rb) + 
                     Dir.glob("test/**/*") + Dir.glob("spec/**/*") + Dir.glob("src/**/*")
  s.executables  = []
  s.require_path = 'lib'
  
  s.add_dependency("swt")
end
