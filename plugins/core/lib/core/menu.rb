
module Redcar
  # The Redcar::Menu module registers the context menu services
  # on startup and initializes the MenuBuilder.
  class Menu
    class << self
      def main
        @main_menus ||= []
      end
      
      def get_main(name)
        menu = main.find{|m| m.name == name}
        unless menu
          menu = new(name)
          @main_menus << menu
        end
        menu
      end
      
      def context
        @context_menus ||= {}
      end
      
      def get_context(name)
        @context_menus[name] ||= new(name)
      end
    end
    
    def initialize(name)
      @name = name
    end
    
    def get_submenu(submenu_name)
      submenu = items.find {|item| item.is_a?(Menu) and item.name == submenu_name}
      unless submenu
        submenu = Menu.new(submenu_name)
        items << submenu
      end
      submenu
    end
    
    def add_item(item_name, command)
      command.menu = self
      new_item = Item.new(item_name, command)
      command.menu_item = new_item
      items << new_item
    end
    
    def gtk_menu_item
      @gtk_menu_item ||= Gtk::MenuItem.new(name)
    end
    
    class Item
      attr_accessor :name, :command
      
      def initialize(name, command)
        @name, @command = name, command
      end
      
      def gtk_menu_item
        return @gtk_menu_item if @gtk_menu_item
        if icon = command.get(:icon) and
           icon != "none"
          gtk_menu_item = Gtk::ImageMenuItem.create(icon, name)
        else
          gtk_menu_item = Gtk::MenuItem.new(name)
        end
        if key = command.get(:key)
          if keybinding = Keymap.display_key(key)
            Item.make_gtk_menuitem_hbox(gtk_menu_item, keybinding)
          end
        end
        @gtk_menu_item = gtk_menu_item
      end
      
      def self.make_gtk_menuitem_hbox(c, keybinding)
        child = c.child
        c.remove(child)
        hbox = Gtk::HBox.new
        child.set_size_request(200, 0)
        hbox.pack_start(child, false)
        accel = keybinding.to_s
        l = Gtk::Label.new(accel)
        l.justify = Gtk::JUSTIFY_RIGHT
        l.set_padding(10, 0)
        l.xalign = 1
        hbox.pack_end(l, true)
        l.show
        hbox.show
        c.add(hbox)
      end
    end
    
    class SeparatorItem
    end
    
    attr_accessor :name
    
    def items
      @items ||= []
    end
    
    def self.load
    end
    
    def self.start
      register_context_menu_services
    end
    
    def self.stop
      remove_context_menu_services
    end
    
    def self.remove_context_menu_services
      bus['/redcar/services/context_menu_popup/'].prune
      bus['/redcar/services/context_menu_options_popup/'].prune
    end
    
    def self.register_context_menu_services
      bus['/redcar/services/context_menu_popup/'].set_proc do |name, button, time|
        context_menu_popup(name, button, time)
      end
      
      bus['/redcar/services/context_menu_options_popup/'].set_proc do |entries|
        context_menu_options_popup(entries)
      end
    end
    
    def self.context_menu_popup(name, button, time)
      slot = bus['/redcar/menus/context/'+name]
      unless slot.attr_gtk_menu
        gtk_menu = Gtk::Menu.new
        MenuDrawer.draw_menus1(slot, gtk_menu)
        slot.attr_gtk_menu = gtk_menu
        gtk_menu.show
      end
      slot.attr_gtk_menu.popup(nil, nil, button, time)
    end
      
    # entries :: [Maybe String, String, String]
    def self.context_menu_options_popup(entries)
      slot = bus['/redcar/gtk/context_options_menu/']
      gtk_menu = Gtk::Menu.new
      slot.data = gtk_menu
      i = 1
      gtk_menu_items = entries.map do |icon, name, command|
        gtk_menuitem = if icon
              Gtk::ImageMenuItem.create icon, name
            else
              Gtk::MenuItem.new name
            end
        Item.make_gtk_menuitem_hbox(gtk_menuitem, i.to_s)
        i += 1
        MenuDrawer.connect_item_signal(command, gtk_menuitem)
        gtk_menu.append(gtk_menuitem)
      end
      gtk_menu.show_all
      eb = Gdk::EventButton.new(Gdk::Event::BUTTON_PRESS)
      gtk_menu.signal_connect("key-press-event") do |_, gdk_eventkey|
        kv = gdk_eventkey.keyval
        ks = gdk_eventkey.state - Gdk::Window::MOD2_MASK
        ks = ks - Gdk::Window::MOD4_MASK
        key = Gtk::Accelerator.get_label(kv, ks)
        if key =~ /^\d$/
          if entry = entries[key.to_i-1]
            command = entry[2]
            gtk_menu.popdown
            begin
              command.new.do
            rescue Object => e
              puts e
              puts e.message
              puts e.backtrace
            end
          end
        end
        false
      end
      
      gtk_menu.popup(nil, nil, eb.button, eb.time) do |_, x, y, _| [x, y]
        tab = Redcar.tab
        tv = tab.view
        gdk_rect = tv.get_iter_location(tab.document.cursor_iter)
        x = gdk_rect.x+gdk_rect.width
        y = gdk_rect.y+gdk_rect.height
        win = tv.get_window Gtk::TextView::WINDOW_WIDGET
        winx, winy = Redcar.win.position
        _, mh = gtk_menu.size_request
        tv.buffer_to_window_coords(Gtk::TextView::WINDOW_WIDGET, x+winx, y+winy+mh+30)
      end
    end
  end
  
  module MenuBuilder
    class << self
      attr_reader :menu
    end
    
    def main_menu(menu_name, &block)
      # puts "main_menu(#{menu_name.inspect})"
      MenuBuilder.menu = Menu.get_main(menu_name)
      MenuBuilder.command_scope = ""
      MenuBuilder.class_eval(&block)
      MenuBuilder.command_scope = ""
    end
    
    def context_menu(menu_name, &block)
      # puts "context_menu(#{menu_name.inspect})"
      MenuBuilder.menu = Menu.get_context(menu_name)
      MenuBuilder.command_scope = ""
      MenuBuilder.class_eval(&block)
      MenuBuilder.command_scope = ""
    end
    
    class << self
      attr_accessor :menu_scope, :command_scope, :menu
      
      def item(item_name, command_name, options={})
        # puts "item(#{item_name.inspect}, #{command_name.inspect}, #{options.inspect})"
        command = bus("/redcar/commands/#{command_scope}/#{command_name}").data
        MenuBuilder.menu.add_item(item_name, command)
      end
      
      def separator
        MenuBuilder.menu.items << Menu::SeparatorItem.new
      end
      
      def submenu(name, &block)
        # puts "submenu(#{name.inspect})"
        old_menu = MenuBuilder.menu
        MenuBuilder.menu = menu.get_submenu(name)
        MenuBuilder.class_eval(&block)
        MenuBuilder.menu = old_menu
      end
    end
  end
  
  module MenuDrawer #:nodoc:
    class << self
      def clear_menus
        (@toplevel_gtk_menuitems||={}).each do |uuid, gtk_menuitem|
          mb = bus["/gtk/window/menubar"].data
          if mb.children.include? gtk_menuitem
            mb.remove(gtk_menuitem)
          end
        end
        @toplevel_gtk_menuitems = {}
        @gtk_menuitems = {}
      end
      
      def draw_menus(window)
        clear_menus        
        Menu.main.each do |main_menu|
          gtk_menu = Gtk::Menu.new
          gtk_menuitem = main_menu.gtk_menu_item
          @toplevel_gtk_menuitems[main_menu.name] = gtk_menuitem
          gtk_menuitem.submenu = gtk_menu
          gtk_menuitem.show
          window.gtk_menubar.append(gtk_menuitem)
          draw_menus1(main_menu, gtk_menu)
        end
      end
      
      def draw_menus1(parent_menu, gtk_menu)
        parent_menu.items.each do |menu_item|
          if menu_item.is_a?(Menu::SeparatorItem)
            gtk_menuitem = Gtk::SeparatorMenuItem.new
          else
            if menu_item.is_a?(Menu::Item)
              gtk_menuitem = menu_item.gtk_menu_item
              connect_item_signal(menu_item.command, gtk_menuitem)
              gtk_menuitem.sensitive = menu_item.command.executable?(Redcar.tab)
            elsif menu_item.is_a?(Menu)
              gtk_menuitem = menu_item.gtk_menu_item
              gtk_submenu = Gtk::Menu.new
              gtk_menuitem.submenu = gtk_submenu
              draw_menus1(menu_item, gtk_submenu)
            else
              raise "found a #{menu_item.class} inside a Redcar::Menu's items"
            end
          end
          gtk_menu.append(gtk_menuitem)
          gtk_menuitem.show
        end
      end
      
      def connect_item_signal(command, gtk_menuitem)
        gtk_menuitem.signal_connect("activate") do
          begin
            command.new.do
          rescue Object => e
            puts e
            puts e.message
            puts e.backtrace
          end
        end
      end
      
      def set_active(menu_item, val)
        menu_item.gtk_menu_item.sensitive = val
      end
    end
  end
end

