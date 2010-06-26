lib, version = File::basename(File::dirname(File::expand_path(__FILE__))).split %r/-/, 2

require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name = lib 
  s.version = version 
  s.platform = Gem::Platform::RUBY
  s.summary = lib 

  s.files = Dir["lib/*"] + Dir["bin/*"]

  s.require_path = "lib" 
  s.autorequire = lib 

  s.has_rdoc = File::exist? "doc" 
  s.test_suite_file = "test/#{ lib }.rb" if File::directory? "test"

  s.author = "Ara T. Howard"
  s.email = "ara.t.howard@noaa.gov"
  s.homepage = "http://codeforpeople.com/lib/ruby/#{ lib }/"
end
