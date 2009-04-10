
module Redcar
  # This class manages Textmate bundles. On Redcar startup
  # it will scan for and load bundle information for all bundles
  # from "redcar/textmate/".
  class Bundle
    include FreeBASE::DataBusHelper

    def self.load #:nodoc:
      load_bundles(App.textmate_share_dir+"/Bundles/")
    end
        
    def self.load_bundles(dir) #:nodoc:
      Dir.glob(dir+"*").each do |bdir|
        if bdir =~ /\/([^\/]*)\.tmbundle/
          name = $1
          Redcar::Bundle.new name, bdir
        end
      end
    end

    class << self
      attr_accessor :bundles
    end
    
    # Translates a Textmate key equivalent into a Redcar
    # keybinding. 
    def self.translate_key_equivalent(keyeq, name=nil)
      if keyeq
        key_str      = keyeq.at(-1)
        case key_str
        when "\n"
          letter = "Return"
        else
          letter = key_str.gsub("\e", "Escape")
        end
        modifier_str = keyeq[0..-2]
        modifiers = modifier_str.split("").map do |modchar|
          case modchar
          when "^" # TM: Control
            [2, "Ctrl"]
          when "~" # TM: Option
            [3, "Alt"]
          when "@" # TM: Command
            [1, "Super"]
          when "$"
            [4, "Shift"]
          else
            App.log.info "unknown key_equivalent: #{keyeq}"
            return nil
          end
        end
        if letter =~ /^[[:alpha:]]$/ and letter == letter.upcase
          modifiers << [4, "Shift"]
        end
        modifiers = modifiers.sort_by {|a| a[0]}.map{|a| a[1]}.uniq
        res = if modifiers.empty?
          letter
        else
          modifiers.join("+") + "+" + (letter.length == 1 ? letter.upcase : letter)
        end
        res
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
    
    def self.find_bundle_with_grammar(grammar)
      bundles.each do |bundle|
        if Dir[bundle.dir+"/Syntaxes/*"].map{|dir| dir.split("/").last}.include?(grammar.filename)
          return bundle
        end
      end
      nil
    end
    
    attr_accessor :name, :dir
    
    # Do not call this directly. Retrieve a loaded bundle
    # with:
    #
    #   Redcar::Bundle.get('Ruby')
    def initialize(name, dir)
      @name = name
      @dir  = dir
      bus("/redcar/bundles/#{name}").data = self
      load_info
      load_command_hashes
      
      Bundle.bundles ||= []
      Bundle.bundles << self
    end
    
    # A hash of information about this Bundle
    def info
      @info ||= load_info
    end
    
    def load_info #:nodoc
      App.with_cache("info", @name) do
        if File.exist?(info_filename)
          xml = IO.read(info_filename)
          Redcar::Plist.plist_from_xml(xml)[0]
        end
      end
    end
    
    def info_filename
      @dir + "/info.plist"
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
            puts e.message
            puts e.backtrace[0..10]
          end
        end
        prefs
      end
    end
    
    attr_writer :snippets
    
    def snippets
      return @snippets if @snippets
      raise "Asked for bundle snippets, but they have not been generated. " +
        "Use Bundle.make_redcar_snippets_with_range(range)."
    end
    
    class << self
      attr_reader :snippet_lookup
    end
    
    def self.register_snippet_for_lookup(snippet_hash, snippet_command)
      @snippet_lookup ||= Hash.new {|h, k| h[k] = Hash.new {|h, k| h[k] = [] } }
      @snippet_lookup[snippet_hash["scope"]||""][snippet_hash["tabTrigger"]] << snippet_command
    end
    
    # A array of this bundle's snippets. Snippets are cached 
    def snippet_hashes
      @snippet_hashes ||= load_snippet_hashes
    end
    
    def load_snippet_hashes #:nodoc:
      App.with_cache("snippets", @name) do
        hashes = {}
        Dir.glob(@dir+"/Snippets/*").each do |snipfile|
          begin
            xml = IO.readlines(snipfile).join
            snip = Redcar::Plist.plist_from_xml(xml)[0]
            hashes[snip["uuid"]] = snip
          rescue Object => e
            puts "There was an error loading #{snipfile}"
            puts e.message
            puts e.backtrace[0..10]
          end
        end
        hashes
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
    
    attr_writer :commands
    
    def commands
      return @commands if @commands
      raise "Asked for bundle commands, but they have not been generated. " +
        "Use Bundle.make_redcar_commands_with_range(range)."
    end
    
    # An array of this bundle's commands. Cached.
    def command_hashes
      @command_hashes ||= load_command_hashes
    end
    
    def load_command_hashes
      App.with_cache("commands", @name) do
        hashes = {}
        Dir.glob(@dir+"/Commands/*").each do |command_filename|
          begin
            xml = IO.read(command_filename)
            hash_info = Redcar::Plist.plist_from_xml(xml)[0]
            hash_info["file"] = command_filename
            hashes[hash_info["uuid"]] = hash_info
          rescue Object => e
            puts "There was an error loading #{command_filename}"
            puts e.message
            puts e.backtrace
            exit
          end
        end
        hashes
      end
    end
    
    def self.create_snippet_command(snip, bundle)
      command_class = Class.new(Redcar::SnippetCommand)
      command_class.range Redcar::Window
      command_class.name = snip["name"]
      command_class.content = snip["content"]
      command_class.bundle = bundle
      if snip["scope"]
        command_class.scope(snip["scope"])
      end
      def command_class.inspect
        "#<SnippetCommand: #{@name}>"
      end
      if tab_trigger = snip["tabTrigger"]
        command_class.tab_trigger = tab_trigger
        register_snippet_for_lookup(snip, command_class)
      end
      if snip["keyEquivalent"]
        keyb = Redcar::Bundle.translate_key_equivalent(snip["keyEquivalent"])
        if keyb
          command_class.key(keyb)
        end
      end
      command_class
    end
    
    def self.make_redcar_snippets_from_class(klass, range)
      start = Time.now
      bundles.each do |bundle|
        bundle.snippets = {}
        bundle.snippet_hashes.each do |uuid, snip|
          Bundle.uuid_map[uuid] = create_snippet_command(snip, bundle)
        end
      end
      puts "loaded snippet objects in #{Time.now - start}s"
    end
    
    def self.make_redcar_commands_with_range(range)
      i = 0
      start = Time.now
      bundles.each do |bundle|
        bundle.commands = {}
        bundle.command_hashes.each do |uuid, hash|
          i += 1
          new_command = Class.new(Redcar::ShellCommand)
          new_command.range Redcar::EditTab
          if key = Bundle.translate_key_equivalent(hash["keyEquivalent"], bundle.name + " | " + hash["name"])
            new_command.key key
          end
          new_command.scope hash["scope"]
          if hash["input"]
            new_command.input hash["input"].underscore.intern
          end
          if hash["fallbackInput"]
            new_command.fallback_input hash["fallbackInput"].underscore.intern
          end
          if hash["output"]
            new_command.output hash["output"].underscore.intern
          end
          
          new_command.tm_uuid = uuid
          new_command.bundle = bundle
          new_command.shell_script = hash["command"]
          new_command.name = hash["name"]
          bundle.commands[uuid] = new_command
          Bundle.uuid_map[uuid] = new_command
        end
      end
      puts "made #{i} Commands in #{Time.now - start}s"
    end
    
    def about_command
      return @about_command if @about_command
      @about_command = Class.new(Redcar::Command)
      @about_command.class_eval %Q{
        def execute
          bundle = bus("/redcar/bundles/#{name}/").data 
          BundleInfoCommand.new(bundle).do
        end
      }
      @about_command.icon :ABOUT
      @about_command
    end
    
    def self.build_bundle_menus
      # require 'ruby-prof'
      start = Time.now
      # RubyProf.start
      main_bundle_menu = Menu.get_main("Bundles")
      bundles.sort_by(&:name).each do |bundle|
        bundle_menu = main_bundle_menu.get_submenu(bundle.name)
        about_item = bundle_menu.add_item("About", bundle.about_command)
        build_bundle_menu(bundle_menu, (bundle.info["mainMenu"]||{})["items"]||[], bundle)
      end
      # result = RubyProf.stop
      # printer = RubyProf::GraphHtmlPrinter.new(result)
      # printer.print(STDOUT, :min_percent => 1)
      puts "built bundle menus in #{Time.now - start}s"
    end

    def self.build_bundle_menu(bundle_menu, uuids, bundle)
      uuids.each do |uuid|
        if uuid =~ /^-+$/
          bundle_menu.items << Menu::SeparatorItem.new
        elsif item = uuid_map[uuid]
          unless item.name and item.name != ""
            next
          end
          bundle_menu.add_item(item.name, item)
        elsif sub_menu = (bundle.info["mainMenu"]["submenus"]||[])[uuid]
          bundle_submenu = bundle_menu.get_submenu(sub_menu["name"])
          build_bundle_menu(bundle_submenu, sub_menu["items"], bundle)
        end
      end
    end
      
    def self.uuid_map
      @uuid_map ||= {}
    end
  end
end
