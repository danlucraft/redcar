
module Redcar
  module Menu
    extend FreeBASE::StandardPlugin
    
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
    
  module ContextMenuBuilder
    
    $BUS['/redcar/services/context_menu_popup/'].set_proc do |name, button, time|
      slot = $BUS['/redcar/menus/context/'+name]
      unless slot.attr_gtk_menu
        gtk_menu = Gtk::Menu.new
        Redcar::Menu.draw_menus1(slot, gtk_menu)
        slot.attr_gtk_menu = gtk_menu
        gtk_menu.show
      end
      slot.attr_gtk_menu.popup(nil, nil, button, time)
    end
    
    # entries :: [Maybe String, String, String]
    $BUS['/redcar/services/context_menu_options_popup/'].set_proc do |entries|
      gtk_menu = Gtk::Menu.new
      i = 1
      gtk_menu_items = entries.map do |icon, name, command|
        p name
        c = if icon
              Gtk::ImageMenuItem.create icon, name
            else
              Gtk::MenuItem.new name
            end
        gtk_menuitem = Menu.make_gtk_menuitem_hbox(c, i.to_s)
        i += 1
        Menu.connect_item_signal(command, gtk_menuitem)
        gtk_menu.append(gtk_menuitem)
      end
      gtk_menu.show_all
      eb = Gdk::EventButton.new(Gdk::Event::BUTTON_PRESS)
      gtk_menu
      gtk_menu.popup(nil, nil, eb.button, eb.time) do |_, x, y, _| [x, y]
        tab = Redcar.current_tab
        tv = tab.textview
        gdk_rect = tv.get_iter_location(tab.cursor_iter)
        x = gdk_rect.x+gdk_rect.width
        y = gdk_rect.y+gdk_rect.height
        win = tv.get_window Gtk::TextView::WINDOW_WIDGET
        winx, winy = win.position
        _, mh = gtk_menu.size_request
        tv.buffer_to_window_coords(Gtk::TextView::WINDOW_WIDGET, x+winx, y+winy+mh)
      end
    end
    
    def context_menu(name)
      $menunum ||= 0
      $menunum += 1
      bits = name.split("/")
      build = ""
      bits.each do |bit|
        build += "/" + bit
        $BUS['/redcar/menus/context/'+build].attr_id = $menunum
        $menunum += 1
      end
      slot = $BUS['/redcar/menus/context/'+name]
      yield b = Builder.new
      slot.data = b
      slot.attr_menu_entry = true
      slot.attr_gtk_menu = nil
      slot.attr_id = $menunum
      $menunum += 1
    end
    
    def context_menu_separator(name)
      slot = $BUS['/redcar/menus/context/'+name+'/separator_'+$menunum.to_s]
      slot.attr_id = $menunum
      $menunum += 1
    end
    
    class Builder
      attr_accessor :command, :icon, :keybinding
      
      def [](v)
        instance_variable_get("@"+v.to_s)
      end
      
    end
  end
  
  module MenuBuilder
    def menu(name)
      $menunum ||= 0
      $menunum += 1
      bits = name.split("/")
      build = ""
      bits.each do |bit|
        build += "/" + bit
        $BUS['/redcar/menus/menubar/'+build].attr_id = $menunum
        $menunum += 1
      end
      slot = $BUS['/redcar/menus/menubar/'+name]
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
      slot = $BUS['/redcar/menus/menubar/'+name+'/separator_'+$menunum.to_s]
      slot.attr_id = $menunum
      $menunum += 1
    end
      
    class Builder
      attr_accessor :command, :icon, :keybinding
      
      def [](v)
        instance_variable_get("@"+v.to_s)
      end
    end
  end
  
  class Menu
    class << self
      def set_node_id(node)
        node.attr_id = $menunum
        $menunum += 1
      end
      
      def clear_menus
        (@toplevel_gtk_menuitems||={}).each do |uuid, gtk_menuitem|
          Redcar.menubar.remove(gtk_menuitem)
        end
        @toplevel_gtk_menuitems = {}
        @gtk_menuitems = {}
      end
      
      def make_gtk_menuitem_hbox(c, keybinding)
        child = c.child
        c.remove(child)
        hbox = Gtk::HBox.new
        child.set_size_request(120, 0)
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
              keybinding = KeyStroke.parse(command[:keybinding]).to_s
            end
          end
        end
        if keybinding
          make_gtk_menuitem_hbox(c, keybinding)
        end
        c
      end

      def draw_menus
        clear_menus        
        $BUS['/redcar/menus/menubar/'].children.
          sort_by(&:attr_id).each do |slot|
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
        parent.children.sort_by(&:attr_id).each do |slot|
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
