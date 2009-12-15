
$:.push File.join(File.dirname(__FILE__))

require 'rbconfig'

if Config::CONFIG["RUBY_INSTALL_NAME"] == "jruby"
  require 'redcar/boot'
else
  require 'redcar/runner'
  runner = Redcar::Runner.new
  runner.spin_up
end