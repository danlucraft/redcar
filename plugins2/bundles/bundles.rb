
module Redcar
  # This class manages Textmate bundles. On Redcar startup
  # it will scan for and load bundle information for all bundles
  # in "/usr/local/share/textmate/Bundles" or "/usr/share/textmate/Bundles"
  class BundlesPlugin < Redcar::Plugin

    def self.load(plugin) #:nodoc:
      Kernel.load File.dirname(__FILE__) + "/commands/bundle_info_command.rb"
      load_bundles(App.textmate_share_dir+"/Bundles/")
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
    class << self
      attr_accessor :bundles
    end
    
    # Translates a Textmate key equivalent into a Redcar
    # keybinding. 
    def self.translate_key_equivalent(keyeq)
      if keyeq
        key_str      = keyeq.at(-1)
#        p keyeq if keyeq == "$\n"
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
        res = if modifiers.empty?
          letter
        else
          modifiers.join("+") + "+" + letter.upcase
        end
#         puts "#{keyeq.inspect.ljust(10)} -> #{res.inspect}" if keyeq == "$\n"
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
    
    attr_accessor :name
    
    # Do not call this directly. Retrieve a loaded bundle
    # with:
    #
    #   Redcar::Bundle.get('Ruby')
    def initialize(name, dir)
      @name = name
      @dir  = dir
      bus("/redcar/bundles/#{name}").data = self
      load_info
      load_commands
      
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
          rescue Object => e
            puts "There was an error loading #{snipfile}"
            puts e.message
            puts e.backtrace[0..10]
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
    
    # An array of this bundle's commands. Cached.
    def commands
      @commands ||= load_commands
    end
    
    def load_commands
      App.with_cache("commands", @name) do
        temps = {}
        Dir.glob(@dir+"/Commands/*").each do |command_filename|
          begin
            xml = IO.read(command_filename)
            tempinfo = Redcar::Plist.plist_from_xml(xml)[0]
            tempinfo["file"] = command_filename
            temps[tempinfo["uuid"]] = tempinfo
          rescue Object => e
            puts "There was an error loading #{command_filename}"
            puts e.message
            puts e.backtrace
            exit
          end
        end
        temps
      end
    end
    
    def self.build_bundle_menus
      root_menu_slot = bus['/redcar/menus/menubar/Bundles']
      MenuBuilder.set_menuid(root_menu_slot)
      bundles.sort_by(&:name).each do |bundle|
        bundle_menu_slot = root_menu_slot[bundle.name]
        MenuBuilder.set_menuid(bundle_menu_slot)
        about_slot = bundle_menu_slot["About"]
        MenuBuilder.set_menuid(about_slot)
        about_command = Class.new(Redcar::Command)
        about_command.class_eval %Q{
          def execute
            bundle = bus("/redcar/bundles/#{bundle.name}/").data 
            BundleInfoCommand.new(bundle).do
          end
        }
        about_command.icon :ABOUT
        about_slot.data = about_command
        about_slot.attr_menu_entry = true
        ((bundle.info["mainMenu"]||{})["items"]||[]).each do |uuid|
          build_bundle_menu(bundle_menu_slot, (bundle.info["mainMenu"]||{})["items"]||[], bundle) 
        end
      end
    end
    
    def self.build_bundle_menu(menu_slot, uuids, bundle)
      uuids.each do |uuid|
        command_slot = nil
        if command_slot = bus("/redcar/bundles/#{bundle.name}/commands/#{uuid}", true)
          command = command_slot.data
          item_slot = menu_slot[command.name.gsub("/", "\\")]
          MenuBuilder.set_menuid(item_slot)
          item_slot.data = command
          item_slot.attr_menu_entry = true
        end
      end
    end
      
    def self.build_bundle_menu_old(binfo, menu_name, menu_hash, commands)
      menu_hash.each do |uuid|
        if uuid =~ /---------/
          menu_separator(menu_name)
        elsif command = commands[uuid]
          menu(menu_name+"/"+command['name']) do |mb|
            mb.command = "Bundles/#{binfo['name']}/#{command['name']}"
            mb.icon = :EXECUTE
            mb.keybinding = ""
          end
        else
          submenu_hash = binfo['mainMenu']['submenus'][uuid]
          if submenu_hash
            root = bus['/redcar/menus/menubar/'+menu_name+'/'+
              submenu_hash['name'].gsub("/", " or ")
            ]
            Redcar::Menu.set_node_id(root)
            build_bundle_menu(binfo, 
                menu_name+"/"+submenu_hash['name'].gsub("/", " or "),
                submenu_hash['items'],
                commands
              )
          end
        end
      end
    end
  end
end
