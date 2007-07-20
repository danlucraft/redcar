
module Gtk
  class ImageMenuItem
    # Helper to create a Gtk::ImageMenuItem from a string
    # corresponding to a Gtk::Stock constant, and a string
    # of text for the item label.
    # e.g. stock_name = "FILE" -> Gtk::Stock::FILE.
    def self.create(stock_name, text)
      gtk_menuitem = Gtk::ImageMenuItem.new(text)
      stock = Gtk::Stock.const_get(stock_name)
      iconimg = Gtk::Image.new(stock, 
                               Gtk::IconSize::MENU)
      gtk_menuitem.image = iconimg
      gtk_menuitem
    end
  end
end

module Redcar  
  class << self
    attr_accessor :menubar
  end
  
  def self.context_menus
    @@context_menus ||= {}
  end
  
  def self.add_command(id, block)
    @@commands ||= {}
    @@commands[id] = block
  end
  
  def self.command(id)
    @@commands[id].call(Redcar.current_pane, Redcar.current_tab)
  end
    
  class ContextMenu
  end
  
  class Menu
    INPUTS = [
              "None", "Document", "Line", "Word", 
              "Character", "Scope", "Nothing", 
              "Selected Text"
             ]
    OUTPUTS = [
               "Discard", "Replace Selected Text", 
               "Replace Document", "Replace Line", "Insert As Text", 
               "Insert As Snippet", "Show As Html",
               "Show As Tool Tip", "Create New Document",
               "Replace Input", "Insert After Input"
              ]
    ACTIVATIONS = ["Key Combination"]
    class << self
      attr_accessor :menus, :menu_defs, :commands
      def menus
        load_menus
      end
      
      def original_version(uuid)
        @menu_defs_original[uuid] ||
          @commands_original[uuid]
      end
      
      def load_menus
        commands = Redcar.image.find_with_tags(:core, :command)
        menudefs  = Redcar.image.find_with_tags(:core, :menudef)
        menu_tree = Redcar.image.find_with_tags(:core, :menu_layout)
        @menu_defs = {}
        @commands = {}
        commands.each do |comm|
          @commands[comm.uuid] = comm.data
        end
        menudefs.each do |menu|
          @menu_defs[menu.uuid] = menu.data
        end
        @menus = menu_tree[0]
        @menus_uuid = menu_tree[0].uuid
        return [@menus, @menu_defs, @commands]
        
      end
      
      def save_menus
        Redcar.image[@menus_uuid] = @menus
        @commands.each do |uuid, comm|
          if !Redcar.image.include? uuid
            Redcar.image[uuid] = comm
            Redcar.image.tag(uuid, :core, :command)
          elsif comm != Redcar.image[uuid].data
            Redcar.image[uuid] = comm
          end
        end
        @menu_defs.each do |uuid, menu|
          if !Redcar.image.include? uuid
            Redcar.image[uuid] = menu
            Redcar.image.tag(uuid, :core, :menudef)
          elsif menu != Redcar.image[uuid].data
            Redcar.image[uuid] = menu
          end
        end
        Redcar.image.cache
      end
      
      def create_menus
        (@gtk_menuitems||=[]).each do |gtk_menuitem|
          Redcar.menubar.remove(gtk_menuitem)
        end
        @gtk_menuitems = []
        @menus.each do |menu|
          uuid = menu.keys[0]
          menu_def = @menu_defs[uuid]
          gtk_menu = Gtk::Menu.new
          if menu_def[:icon] and menu_def[:icon] != "none"
            gtk_menuitem = Gtk::ImageMenuItem.create(menu_def[:icon],
                                                     menu_def[:name])
          else
            gtk_menuitem = Gtk::MenuItem.new(menu_def[:name])
          end
          @gtk_menuitems << gtk_menuitem
          gtk_menuitem.submenu = gtk_menu
          gtk_menuitem.show
          if menu_def[:visible]
            Redcar.menubar.append(gtk_menuitem)
          end
          if menu_def[:enabled]
            add_menu_items(menu.values[0], gtk_menu)
          end
        end
      end
      
      def add_menu_items(menu_entries, gtk_menu)
        menu_entries.each do |entry|
          case entry
          when Hash # it's a menu
            uuid = entry.keys[0]
            menu_def = @menu_defs[uuid]
            if menu_def[:enabled]
              if menu_def[:icon] and menu_def[:icon] != "none"
                gtk_menuitem = Gtk::ImageMenuItem.create(menu_def[:icon],
                                                         menu_def[:name])
              else
                gtk_menuitem = Gtk::MenuItem.new(menu_def[:name])
              end
              gtk_menuitem.show
              gtk_submenu = Gtk::Menu.new
              gtk_menuitem.submenu = gtk_submenu
              add_menu_items(entry.values[0], gtk_submenu)
            end
            if menu_def[:visible]
              gtk_menu.append(gtk_menuitem)
            end
          when String # it's an item
            uuid = entry
            if uuid == "---"
              gtk_sep = Gtk::SeparatorMenuItem.new
              gtk_menu.append(gtk_sep)
              gtk_sep.show
            else
              command_def = @commands[uuid]
              unless command_def
                puts "Missing menu item definition for :#{uuid}"
                next
              end
              if command_def[:enabled]
                if command_def[:icon] and command_def[:icon] != "none"
                  gtk_menuitem = Gtk::ImageMenuItem.create(command_def[:icon],
                                                           command_def[:name])
                else
                  gtk_menuitem = Gtk::MenuItem.new(command_def[:name])
                end
                gtk_menuitem.show
                gtk_menuitem.signal_connect("activate") do 
                  command = Command.new(command_def)
                  begin
                    command.execute
                  rescue Object => e
                    puts e
                    puts e.message
                  end
                end
#                 if command_def[:activated_by] == :key_combination and
#                     command_def[:activated_by_value]
#                   keybinding = Redcar::KeyBinding.parse(
#                                                         command_def[:activated_by_value])
#                   this_name = command_def[:name].gsub(/_|-|\s/, "").downcase
#                   Redcar.GlobalKeymap.class.class_eval do
#                     keymap keybinding, "menu_#{this_name}".intern
#                     define_method("menu_#{this_name}") do
#                       command = Command.new(command_def)
#                       begin
#                         command.execute
#                       rescue Object => e
#                         puts e
#                         puts e.message
#                       end
#                       # used to do this:
#                       #      Redcar.process_command_error(id, e)
#                     end
#                   end
#                 end
              end

              if command_def[:sensitive] and command_def[:sensitive].to_s.downcase != "nothing"
                gtk_menuitem.sensitize_to(command_def[:sensitive])
              end
              
              if command_def[:visible]
                gtk_menu.append(gtk_menuitem)
              end
            end
          end
        end
      end
    end
    
    include DebugPrinter
    
    attr_accessor :name
    def initialize(menu, name)
      @menu = menu
      @name = name
    end
    def command(name, id, icon=nil, keybinding="", options={}, &block)
      Redcar.add_command(id, block)
#       accel = Gtk::Accelerator.parse(keymap)
#       Gtk::AccelMap.add_entry("<Redcar>/"+name, *accel)
      menuitem = Gtk::ImageMenuItem.new(name)
      menuitem.accel_path = "<Redcar>/"+name
      if keybinding.blank?
        $no_key_count ||= 0
        keybinding = "no_key_#{$no_key_count}"
        $no_key_count += 1
      end
      this_name = self.name.gsub("_", "").downcase
#       Redcar.GlobalKeymap.class.class_eval do
#         keymap keybinding, "menu_#{this_name}_#{id}".intern
#         define_method("menu_#{this_name}_#{id}") do
#           begin
#             block.call(Redcar.current_pane, Redcar.current_tab)
#           rescue Object => e
#             Redcar.process_command_error(id, e)
#           end
#         end
#       end
      menuitem2 = menuitem
      menuitem2.signal_connect("activate") do
        debug_puts keybinding
        begin
          block.call(Redcar.current_pane, Redcar.current_tab)
        rescue Object => e
          Redcar.process_command_error(id, e)
        end
        Redcar.keystrokes.add_to_history(keybinding)
      end
      if icon
        iconimg = Gtk::Image.new(Redcar::Icon.get(icon), 
                                 Gtk::IconSize::MENU)
        menuitem.image = iconimg
      end
      
      if options[:sensitize_to]
        menuitem.sensitize_to(options[:sensitize_to])
      end
      
      menuitem.show
      @menu.append(menuitem)
    end
    
    def submenu(name)
      submenu = Gtk::Menu.new
      yield Menu.new(submenu, name)
      submenu_item = Gtk::MenuItem.new(name)
      submenu_item.submenu = submenu
      submenu.show
      submenu_item.show
      @menu.append(submenu_item)
    end
    
    def separator
      sep = Gtk::SeparatorMenuItem.new
      @menu.append(sep)
      sep.show
    end
  end
  
  def self.context_menu(id, &block)
    menu = self.common(id, block)
    menu.show
    Redcar.context_menus[id] = menu
  end
  
  def self.common(name, block)
    @menus ||= {}
    menu = (@menus[name] ||= Gtk::Menu.new)
    menu.accel_group = $ag
    block.call Menu.new(menu, name)
    menu.show
    menu
  end
  
  def self.menu(name, &block)
    @menus ||= {}
    if @menus[name]
      menu = self.common(name, block)
    else
      menu = self.common(name, block)
      menuitem = Gtk::MenuItem.new(name)
      menuitem.submenu = menu
      menuitem.show
      Redcar.menubar.append(menuitem)
    end
  end
end
