
module Redcar
  # This class manages Textmate bundles. On Redcar startup
  # it will scan for and load bundle information for all bundles
  # in Redcar::App.root_path + "/textmate/Bundles".
  class Bundle
    extend FreeBASE::StandardPlugin
    
    def self.load(plugin) #:nodoc:
      load_bundles(Redcar::App.root_path + "/textmate/Bundles/")
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.load_bundles(dir) #:nodoc:
      Dir.glob(dir+"*").each do |bdir|
        if bdir =~ /\/([^\/]*)\.tmbundle/
          name = $1
          Bundle.new name, bdir
        end
      end
    end
    
    # Return an array of the names of all bundles loaded.
    def self.names
      bus("/redcar/bundles/").children.map &:name
    end
    
    # Get the Bundle with the given name.
    def self.get(name)
      if slot = bus("/redcar/bundles/#{name}", true)
        slot.data
      end
    end
    
    # Do not call this directly. Retrieve a loaded bundle
    # with:
    #
    #   Redcar::Bundle.get('Ruby')
    def initialize(name, dir)
      @name = name
      @dir  = dir
      bus("/redcar/bundles/#{name}").data = self
    end
    
    # A hash of all Bundle preferences.
    def preferences
      @preferences ||= load_preferences
    end
    
    def load_preferences #:nodoc:
      prefs = {}
      Dir.glob(@dir+"/Preferences/*").each do |preffile|
        xml = IO.readlines(preffile).join
        pref = Redcar::Plist.plist_from_xml(xml)[0]
        prefs[pref["name"]] = pref
      end
      prefs
    end
    
    # A array of this bundle's snippets.
    def snippets
      @snippets ||= load_snippets
    end
    
    def load_snippets #:nodoc:
      snippets = []
      Dir.glob(@dir+"/Snippets/*").each do |snipfile|
        xml = IO.readlines(snipfile).join
        snip = Redcar::Plist.plist_from_xml(xml)[0]
        snippets << snip
      end
      snippets
    end
  end
end
