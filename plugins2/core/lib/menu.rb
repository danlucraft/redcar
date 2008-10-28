
module Redcar
  # The Redcar::Menu module registers the context menu services
  # on startup and initializes the MenuBuilder.
  module Menu
    def self.load
      MenuBuilder.init_menuid
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
      p entries
      gtk_menu = Gtk::Menu.new
      i = 1
      gtk_menu_items = entries.map do |icon, name, command|
        gtk_menuitem = if icon
              Gtk::ImageMenuItem.create icon, name
            else
              Gtk::MenuItem.new name
            end
        MenuDrawer.make_gtk_menuitem_hbox(gtk_menuitem, i.to_s)
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
        if entry = entries[key.to_i-1]
          command = entry[2]
          gtk_menu.hide_all
          begin
            command.new.do
          rescue Object => e
            puts e
            puts e.message
            puts e.backtrace
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
#        puts "win.position
        _, mh = gtk_menu.size_request
        tv.buffer_to_window_coords(Gtk::TextView::WINDOW_WIDGET, x+winx, y+winy+mh+30)
      end
    end
  end
  
  module MenuBuilder
    class << self
      attr_reader :menuid
      def init_menuid
        @menuid = 0
      end
      
      def inc_menuid
        @menuid += 1
      end
      
      def set_menuid(slot)
         unless slot.attr_id
          slot.attr_id = @menuid
          inc_menuid
        end
      end
    end
    
    def main_menu(menu, &block)
      MenuBuilder.command_scope = ""
      MenuBuilder.menu_scope    = "menubar/"+menu
      MenuBuilder.class_eval(&block)
      MenuBuilder.command_scope = ""
      MenuBuilder.menu_scope    = ""
    end
    
    def context_menu(menu, &block)
      MenuBuilder.command_scope = ""
      MenuBuilder.menu_scope    = "context/"+menu
      MenuBuilder.class_eval(&block)
      MenuBuilder.command_scope = ""
      MenuBuilder.menu_scope    = ""
    end
    
    class << self
      attr_accessor :menu_scope, :command_scope
      
      def item(item_name, command_name, options={})
        slot = bus("/redcar/menus/#{menu_scope}/#{item_name}")
        slot.data = bus("/redcar/commands/#{command_scope}/#{command_name}").data
        slot.data.menu = "#{menu_scope}/#{item_name}"
        slot.attr_menu_entry = true
        # sets the menuid of this menuitem and it's ancestors if necessary:
        bits = "#{menu_scope}/#{item_name}".split("/")
        build = ""
        bits.each do |bit|
          build += "/" + bit
          set_menuid(bus['/redcar/menus/'+build])
        end
      end
      
      def separator
        slot = bus("/redcar/menus/#{menu_scope}/separator_#{MenuBuilder.menuid}")
        set_menuid(slot)
      end
      
      def submenu(name, &block)
        old_menu_scope = @menu_scope
        @menu_scope += "/#{name}"
        MenuBuilder.class_eval(&block)
        @menu_scope = old_menu_scope
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
      
      def make_gtk_menuitem_hbox(c, keybinding)
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
      
      def make_gtk_menuitem(slot)
        name     = slot.name
        menuitem = slot.data || {}
        c = if icon = (slot.data||null).get(:icon) and 
                icon != "none"
              Gtk::ImageMenuItem.create icon, name
            else
              Gtk::MenuItem.new name
            end
        if slot.data and slot.data.get(:key)
          keybinding = Keymap.display_key(slot.data.get(:key))
        end
        if keybinding
          make_gtk_menuitem_hbox(c, keybinding)
        end
        c
      end

      def draw_menus(window)
        clear_menus        
        bus['/redcar/menus/menubar/'].children.
          sort_by(&:attr_id).each do |slot|
          gtk_menu = Gtk::Menu.new
          gtk_menuitem = make_gtk_menuitem(slot)
          @toplevel_gtk_menuitems[slot.name] = gtk_menuitem
          gtk_menuitem.submenu = gtk_menu
          gtk_menuitem.show
          window.gtk_menubar.append(gtk_menuitem)
          draw_menus1(slot, gtk_menu)
        end
      end
      
      def draw_menus1(parent, gtk_menu)
        parent.children.sort_by(&:attr_id).each do |slot|
          if slot.name =~ /separator/
            gtk_menuitem = Gtk::SeparatorMenuItem.new
          else
            if slot.attr_menu_entry
              gtk_menuitem = make_gtk_menuitem(slot)
              connect_item_signal(slot.data, gtk_menuitem)
              gtk_menuitem.sensitive = slot.data.executable?(Redcar.tab)
            else
              gtk_menuitem = make_gtk_menuitem(slot)
              gtk_submenu = Gtk::Menu.new
              gtk_menuitem.submenu = gtk_submenu
              draw_menus1(slot, gtk_submenu)
            end
            slot.attr_gtk_menuitem = gtk_menuitem
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
      
      def set_active(menu_path, val)
        if gtk_menuitem = bus("/redcar/menus/#{menu_path}").attr_gtk_menuitem
          gtk_menuitem.sensitive = val
        end
      end
    end
  end
end

