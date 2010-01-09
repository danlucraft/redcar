
$:.push File.join(File.dirname(__FILE__))

require 'rbconfig'

require 'redcar/usage'

module Redcar
  VERSION         = '0.3.2dev'
  VERSION_MAJOR   = 0
  VERSION_MINOR   = 3
  VERSION_RELEASE = 2

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

usage = Redcar::Usage.new
usage.version_string
usage.version_requested
usage.help_requested
