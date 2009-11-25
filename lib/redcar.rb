
$:.push(File.join(File.dirname(__FILE__), "..", "freebase2", "lib"))
require 'freebase/freebase'

require 'ruby_extensions'
require 'logging'

# 
module Redcar
  VERSION         = '0.3.0dev'
  VERSION_MAJOR   = 0
  VERSION_MINOR   = 3
  VERSION_RELEASE = 0
  
  ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))

  $FR_CODEBASE          = File.expand_path(File.join(File.dirname(__FILE__)) + "/../")
  $FR_PROJECT           = nil
  $FREEBASE_APPLICATION = "Redcar"
  
  class << self
    attr_reader :freebase_core
  end
  
  def self.root
    ROOT
  end
  
  def self.start
    @freebase_core = FreeBASE::Core.new(*freebase_core_args)
    @freebase_core.startup
  end
  
  def self.load
    @freebase_core = FreeBASE::Core.new(*freebase_core_args)
    @freebase_core.load_plugins
  end
  
  def self.require
    @freebase_core = FreeBASE::Core.new(*freebase_core_args)
    @freebase_core.require_files
  end
  
  def self.pump
    @freebase_core.bus["/system/ui/messagepump"].call()
  end
  
  private
  
  def self.freebase_core_args
    ["properties.yaml", "config/default.yaml"]
  end
end

if ARGV.include?("-v")
  puts "Redcar #{Redcar::VERSION}"
  exit
end