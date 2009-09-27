
module Redcar
  class Plugin
    extend FreeBASE::StandardPlugin
    extend Redcar::PreferenceBuilder
    extend Redcar::MenuBuilder
    include FreeBASE::DataBusHelper
    
    class PluginTransitionException < Exception #:nodoc:
    end
    
    def self.abort
      raise PluginTransitionException, "Plugin transition aborted"
    end
    
    def self.lib(fn)
      Kernel.load File.dirname(caller.first.split(":").first) + "/lib/"+fn+".rb"
    end
    
    def self.command(fn)
      Kernel.load File.dirname(caller.first.split(":").first) + "/commands/"+fn+".rb"
    end
    
    def self.tab(fn)
      Kernel.load File.dirname(caller.first.split(":").first) + "/tabs/"+fn+".rb"
    end
    
    def self.on_load(&block); @on_load = block; end
    def self.on_start(&block); @on_start = block; end
    def self.on_stop(&block); @on_stop = block; end
    def self.on_unload(&block); @on_unload = block; end
    
    def self.load(plugin)
      begin
        @on_load.call if @on_load
        plugin.transition(FreeBASE::LOADED)
      rescue PluginTransitionException
      end
    end
    
    def self.start(plugin)
      begin
        @on_start.call if @on_start
        plugin.transition(FreeBASE::RUNNING)
      rescue PluginTransitionException
      end
    end
    
    def self.stop(plugin)
      begin
        @on_stop.call if @on_stop
        plugin.transition(FreeBASE::LOADED)
      rescue PluginTransitionException
      end
    end
    
    def self.unload(plugin)
      begin
        @on_unload.call if @on_unload
        plugin.transition(FreeBASE::UNLOADED)
      rescue PluginTransitionException
      end
    end
  end
end
