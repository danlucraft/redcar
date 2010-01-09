
$:.push File.join(File.dirname(__FILE__))

require 'rbconfig'

module Redcar
  VERSION         = '0.3.1dev'
  VERSION_MAJOR   = 0
  VERSION_MINOR   = 3
  VERSION_RELEASE = 1

  def self.ensure_jruby
    if Config::CONFIG["RUBY_INSTALL_NAME"] == "jruby"
      boot
    else
      require 'redcar/runner'
      runner = Redcar::Runner.new
      runner.spin_up
    end
  end
  
  def self.boot
    require 'redcar/boot'
  end
end

require 'redcar/installer'
