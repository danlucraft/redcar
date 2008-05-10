
module Redcar
  class Bundle
    # This class manages Textmate bundles. On Redcar startup
    # it will scan for and load bundle information for all bundles
    # in Redcar::App.root_path + "/textmate/Bundles".
    extend FreeBASE::StandardPlugin
    
    def self.load(plugin) #:nodoc:
      load_bundles(Redcar::App.root_path + "/textmate/Bundles/")
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.load_bundles(dir) #:nodoc:
      Dir.glob(dir+"*").each do |bdir|
        if bdir =~ /\/([^\/]*)\.tmbundle/
          name = $1
          Redcar::Bundle.new name, bdir
        end
      end
    end
    
    # Translates a Textmate key equivalent into a Redcar
    # keybinding. 
    def self.translate_key_equivalent(keyeq)
      if keyeq
        key_str      = keyeq.at(-1)
        #        p key_str
        case key_str
        when "\n"
          letter = "Return"
        else
          letter = key_str.gsub("\e", "Escape")
        end
        modifier_str = keyeq.strip[0..-2]
        modifiers = modifier_str.split("").map do |modchar|
          case modchar
          when "^" # TM: Control
            [2, "Super"]
          when "~" # TM: Option
            [3, "Alt"]
          when "@" # TM: Command
            [1, "Ctrl"]
          when "$"
            [4, "Shift"]
          else
            puts "unknown key_equivalent: #{keyeq}"
            return nil
          end
        end.sort_by {|a| a[0]}.map{|a| a[1]}
        if modifiers.empty?
          letter
        else
          modifiers.join("+") + "+" + letter
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
    
    # Yields the given block on each bundle
    def self.each
      bus("/redcar/bundles/").children.each do |slot|
        yield slot.data
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
    
    # A array of this bundle's snippets. Snippets are cached 
    def snippets
      @snippets ||= load_snippets
    end
    
    def load_snippets #:nodoc:
      App.with_cache("snippets", @name) do
        snippets = []
        Dir.glob(@dir+"/Snippets/*").each do |snipfile|
          xml = IO.readlines(snipfile).join
          snip = Redcar::Plist.plist_from_xml(xml)[0]
          snippets << snip
        end
        snippets
      end
    end
    
    # An array of this bundle's templates. Cached.
    def templates
      @templates ||= load_templates
    end
    
    def load_templates
      App.with_cache("templates", @name) do
        temps = []
        Dir.glob(@dir+"/Templates/*").each do |tempdir|
          xml = IO.readlines(tempdir + "/info.plist").join
          tempinfo = Redcar::Plist.plist_from_xml(xml)[0]
          temps << tempinfo
        end
        temps
      end
    end
  end
end
