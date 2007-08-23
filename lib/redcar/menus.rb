
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
        @commands, @menudefs, @snippets, @macros= {}, {}, {}, {}
        Redcar.image.find_with_tags(:command).
          each {|i| @commands[i.uuid] = i}
        Redcar.image.find_with_tags(:menudef).
          each {|i| @menudefs[i.uuid] = i}
        Redcar.image.find_with_tags(:snippet).
          each {|i| @snippets[i.uuid] = i}
        Redcar.image.find_with_tags(:macro).
          each {|i| @macros[i.uuid] = i}
        @menus = Redcar.image.find_with_tags(:menu)
        return [@menus, @menudefs, @commands, @snippets, @macros]
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
      
      def clear_menus
        (@toplevel_gtk_menuitems||={}).each do |uuid, gtk_menuitem|
          Redcar.menubar.remove(gtk_menuitem)
        end
        @toplevel_gtk_menuitems = {}
        @gtk_menuitems = {}
      end
      
      def make_gtk_menuitem(menu_def)
        c = if menu_def[:icon] and menu_def[:icon] != "none"
              Gtk::ImageMenuItem.create(menu_def[:icon],
                                        menu_def[:name])
            else
              Gtk::MenuItem.new(menu_def[:name])
            end
        if menu_def[:activated_by] == :key_combination or
            menu_def[:activated_by] == nil
          child = c.child
          c.remove(child)
          hbox = Gtk::HBox.new
          hbox.pack_start(child)
          accel = menu_def[:activated_by_value].to_s
          hbox.pack_start(l=Gtk::Label.new(accel))
          l.show
          hbox.show
          c.add(hbox)
        end
        c
      end

      def create_menus
        clear_menus
        items_to_add = []
        @menus.each do |menu|
          menu[:toplevel].each do |menu_uuid|
            menu_def = @menudefs[menu_uuid]
            unless gtk_menu = @gtk_menuitems[menu_uuid]
              if menu_def[:visible]
                gtk_menu = Gtk::Menu.new
                gtk_menuitem = make_gtk_menuitem(menu_def)
                @toplevel_gtk_menuitems[menu_uuid] = gtk_menuitem
                gtk_menuitem.submenu = gtk_menu
                gtk_menuitem.show
                @gtk_menuitems[menu_uuid] = gtk_menu
                items_to_add << [menu_def[:position]||100, gtk_menuitem]
              end
            end
            if menu_def[:enabled]
              create_submenu(menu_uuid, menu, gtk_menu)
            end
          end
        end
        items_to_add.sort_by(&its[0]).each do |a|
          gtk_menuitem = a[1]
          Redcar.menubar.append(gtk_menuitem)
        end
      end
      
      def connect_item_signal(item, gtk_menuitem)
        if item.tags.include? :command
          gtk_menuitem.signal_connect("activate") do 
            command = Command.new(item)
            begin
              command.execute
            rescue Object => e
              puts e
              puts e.message
            end
          end
        elsif item.tags.include? :snippet
          gtk_menuitem.signal_connect("activate") do 
            puts "do not know how to activate snippets yet"
          end
        elsif item.tags.include? :macro
          gtk_menuitem.signal_connect("activate") do 
            puts "do not know how to activate macros yet"
          end
        end
      end
      
      def create_submenu(uuid, menu, gtk_menu)
        unless submenu_items = menu[:submenus][uuid]
          raise Exception, "Missing submenu for #{uuid} in #{menu.inspect}"
        end
        items_to_add = []
        submenu_items.each do |item_uuid|
          if item_uuid =~ /---/
            gtk_menuitem = Gtk::SeparatorMenuItem.new
          elsif item_def = @menudefs[item_uuid]
            unless gtk_submenu = @gtk_menuitems[item_uuid]
              gtk_menuitem = make_gtk_menuitem(item_def)
              gtk_submenu = Gtk::Menu.new
              gtk_menuitem.submenu = gtk_submenu
              @gtk_menuitems[item_uuid] = gtk_submenu
            end
            create_submenu(item_uuid, menu, gtk_submenu)
          elsif item_def = @commands[item_uuid] || 
              @snippets[item_uuid] ||
              @macros[item_uuid]
            gtk_menuitem = make_gtk_menuitem(item_def)
            connect_item_signal(item_def, gtk_menuitem)
          elsif
            unless (menu[:deleted]||[]).include? item_uuid
              puts "Missing menu or command definition"+
                " for #{item_uuid}"
            end
          end
          if (item_def and item_def[:visible] and item_def[:enabled]) or
              item_uuid =~ /---/
            gtk_menuitem.redcar_position = (item_def||{})[:position]||100
            items_to_add << gtk_menuitem
          end
        end
        items_to_add.each do |gtk_menuitem|
          gtk_menu.append(gtk_menuitem)
          gtk_menuitem.show
        end
        gtk_menu.children.
          sort_by(&:redcar_position).
          each_with_index {|m, i| gtk_menu.reorder_child(m, i)}
      end
    end
  end
end
