
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
  
  class MenuItem
    attr_accessor :redcar_position
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
  
  module MenuBuilder
    def menu(name)
      $menunum ||= 0
      $menunum += 1
      bits = name.split("/")
      build = ""
      bits.each do |bit|
        build += "/" + bit
        $BUS['/redcar/menus/'+build].attr_id = $menunum
        $menunum += 1
      end
      slot = $BUS['/redcar/menus/'+name]
      yield b = Builder.new
      slot.data = b
      slot.attr_menu_entry = true
      slot.attr_id = $menunum
      $menunum += 1
      if $BUS['/system/state/all_plugins_loaded'].data.to_bool
        Redcar::Menu.draw_menus
      end
    end
    
    def menu_separator(name)
      slot = $BUS['/redcar/menus/'+name+'/separator_'+$menunum.to_s]
      slot.attr_id = $menunum
      $menunum += 1
    end
      
    class Builder
      attr_accessor :command, :icon
      
      def [](v)
        instance_variable_get("@"+v.to_s)
      end
    end
  end
  
  class Menu
    class << self
      def clear_menus
        (@toplevel_gtk_menuitems||={}).each do |uuid, gtk_menuitem|
          Redcar.menubar.remove(gtk_menuitem)
        end
        @toplevel_gtk_menuitems = {}
        @gtk_menuitems = {}
      end
      
      def make_gtk_menuitem(slot)
        name    = slot.name
        builder = slot.data || {}
        c = if icon = builder[:icon] and 
                icon != "none"
              Gtk::ImageMenuItem.create icon, name
            else
              Gtk::MenuItem.new name
            end
        keybinding = builder[:keybinding]
        unless keybinding
          if command = builder[:command]
            command = $BUS['/redcar/commands/'+command.to_s].data
            if command and command[:keybinding]
              keybinding = command[:keybinding]
            end
          end
        end
        if keybinding
          child = c.child
          c.remove(child)
          hbox = Gtk::HBox.new
          hbox.pack_start(child)
          accel = keybinding.to_s
          hbox.pack_start(l=Gtk::Label.new(accel))
          l.show
          hbox.show
          c.add(hbox)
        end
        c
      end

      def draw_menus
        clear_menus
        $BUS['/redcar/menus'].children.
          sort_by(&its.attr_id).each do |slot|
          gtk_menu = Gtk::Menu.new
          gtk_menuitem = make_gtk_menuitem(slot)
          @toplevel_gtk_menuitems[slot.name] = gtk_menuitem
          gtk_menuitem.submenu = gtk_menu
          gtk_menuitem.show
          Redcar.menubar.append(gtk_menuitem)
          draw_menus1(slot, gtk_menu)
        end
      end
      
      def draw_menus1(parent, gtk_menu)
        parent.children.sort_by(&its.attr_id).each do |slot|
          if slot.name =~ /separator/
            gtk_menuitem = Gtk::SeparatorMenuItem.new
          else
            if slot.attr_menu_entry
              gtk_menuitem = make_gtk_menuitem(slot)
              connect_item_signal(slot.data[:command], gtk_menuitem)
            else
              gtk_menuitem = make_gtk_menuitem(slot)
              gtk_submenu = Gtk::Menu.new
              gtk_menuitem.submenu = gtk_submenu
              draw_menus1(slot, gtk_submenu)
            end
          end
          gtk_menu.append(gtk_menuitem)
          gtk_menuitem.show
        end
      end
      
      def connect_item_signal(command_name, gtk_menuitem)
        gtk_menuitem.signal_connect("activate") do 
          c = $BUS['/redcar/commands/'+command_name.to_s].data
          command = Command.new(c)
          begin
            command.execute
          rescue Object => e
            puts e
            puts e.message
            puts e.backtrace
          end
        end
      end
    end
  end
end
