
module Redcar
  class Bundle
    extend FreeBASE::StandardPlugin
    
    def self.load(plugin)
      load_bundles(Redcar::App.root_path + "/textmate/Bundles/")
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.load_bundles(dir)
      Dir.glob(dir+"*").each do |bdir|
        if bdir =~ /\/([^\/]*)\.tmbundle/
          name = $1
          Bundle.new name, bdir
        end
      end
    end
    
    def self.names
      bus("/redcar/bundles/").children.map &:name
    end
    
    def self.get(name)
      if slot = bus("/redcar/bundles/#{name}", true)
        slot.data
      end
    end
    
    def initialize(name, dir)
      @name = name
      @dir  = dir
      bus("/redcar/bundles/#{name}").data = self
    end
    
    def preferences
      @preferences ||= load_preferences
    end
    
    def load_preferences
      prefs = {}
      Dir.glob(@dir+"/Preferences/*").each do |preffile|
        xml = IO.readlines(preffile).join
        pref = Redcar::Plist.plist_from_xml(xml)[0]
        prefs[pref["name"]] = pref
      end
      prefs
    end
  end
end
