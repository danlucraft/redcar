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
    def self.load_menus
      @menus = YAML.load("environment/menus.yaml")
    end
    
    def self.save_menus
      File.open("environment/menus.yaml", "w") do |f| 
        f.puts @menus.to_yaml
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
      Redcar.GlobalKeymap.class.class_eval do
        keymap keybinding, "menu_#{this_name}_#{id}".intern
        define_method("menu_#{this_name}_#{id}") do
          begin
            block.call(Redcar.current_pane, Redcar.current_tab)
          rescue Object => e
            Redcar.process_command_error(id, e)
          end
        end
      end
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
