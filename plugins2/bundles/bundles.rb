
module Redcar
  class BundlesPlugin < Redcar::Plugin
    # This class manages Textmate bundles. On Redcar startup
    # it will scan for and load bundle information for all bundles
    # in Redcar::ROOT + "/textmate/Bundles".
    
    def self.load(plugin) #:nodoc:
      load_bundles(Redcar::ROOT + "/textmate/Bundles/")
      create_logger
      plugin.transition(FreeBASE::LOADED)
    end
    
    class << self
      attr_accessor :logger
    end
    
    def self.load_bundles(dir) #:nodoc:
      main_menu "Bundles" do
        Dir.glob(dir+"*").each do |bdir|
          if bdir =~ /\/([^\/]*)\.tmbundle/
            submenu(name) { }
            name = $1
            Redcar::Bundle.new name, bdir
          end
        end
      end
    end
  end    

  class Bundle
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
            BundlesPlugin.logger.info "unknown key_equivalent: #{keyeq}"
            return nil
          end
        end
        if letter.upcase == letter
          modifiers << [4, "Shift"]
        end
        modifiers = modifiers.sort_by {|a| a[0]}.map{|a| a[1]}.uniq
        if modifiers.empty?
          letter
        else
          modifiers.join("+") + "+" + letter.upcase
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
    
    attr_accessor :name
    
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
      App.with_cache("preferences", @name) do
        prefs = {}
        Dir.glob(@dir+"/Preferences/*").each do |preffile|
          begin
            xml = IO.readlines(preffile).join
            pref = Redcar::Plist.plist_from_xml(xml)[0]
            prefs[pref["name"]] = pref
          rescue Object => e
            puts "There was an error loading #{preffile}"
            #          puts e.message
            #          puts e.backtrace[0..10]
          end
        end
        prefs
      end
    end
    
    # A array of this bundle's snippets. Snippets are cached 
    def snippets
      @snippets ||= load_snippets
    end
    
    def load_snippets #:nodoc:
      App.with_cache("snippets", @name) do
        snippets = []
        Dir.glob(@dir+"/Snippets/*").each do |snipfile|
          begin
            xml = IO.readlines(snipfile).join
            snip = Redcar::Plist.plist_from_xml(xml)[0]
            snippets << snip
          rescue Object
            puts "There was an error loading #{snipfile}"
          end
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
        temps = {}
        Dir.glob(@dir+"/Templates/*").each do |tempdir|
          begin
            xml = IO.readlines(tempdir + "/info.plist").join
            tempinfo = Redcar::Plist.plist_from_xml(xml)[0]
            tempinfo["dir"] = tempdir
            temps[tempinfo["name"]] = tempinfo
          rescue Object
            puts "There was an error loading #{tempdir} templates"
          end
        end
        temps
      end
    end
  end
end
