
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
  
  class Command
    def initialize(hash)
      @def = hash
    end
    
    # Gets the applicable input type, as a symbol. NOT the 
    # actual input
    def valid_input_type
      if primary_input
        @def[:input]
      else
        @def[:fallback_input]
      end
    end
    
    # Gets the primary input.
    def primary_input
      input = input_by_type(@def[:input])
      input == "" ? nil : input
    end
    
    def secondary_input
      input_by_type(@def[:fallback_input])
    end
    
    def input_by_type(type)
      case type
      when :selected_text
        Redcar.tab.selection
      when :document
        Redcar.tab.buffer.text
      when :line
        Redcar.tab.get_line
      when :word
        if Redcar.tab.cursor_iter.inside_word?
          s = Redcar.tab.cursor_iter.backward_word_start!.offset
          e = Redcar.tab.cursor_iter.forward_word_end!.offset
          Redcar.tab.text[s..e]
        end
      when :character
        Redcar.tab.text[Redcar.tab.cursor_iter.offset]
      when :scope
        if Redcar.textview.respond_to? :current_scope_text
          Redcar.textview.current_scope_text
        end
      when :nothing
        nil
      end
    end
    
    def get_input
      primary_input || secondary_input
    end
    
    def tab
      Redcar.current_tab
    end
    
    def output=(val)
      puts :output_is
      puts val
      @output = val
    end
    
#     OUTPUTS = [
#                "Discard", "Replace Selected Text", 
#                "Replace Document", "Insert As Text", 
#                "Insert As Snippet", "Show As HTML",
#                "Show As Tool Tip", "Create New Document",
#                "Replace Input", "Insert After Input"
#               ]
    def direct_output(output)
      case @def[:output]
      when :replace_document
        tab.replace output
      when :replace_input
        case valid_input_type
        when :selected_text
          tab.replace_selection {|_| output}
        when :line
          tab.replace_line {|_| output}
        when :document
          tab.replace output
        when :word
          Redcar.tab.text[@s..@e] = output
        end
      when :insert_after_input
        case valid_input_type
        when :selected_text
          s, e = tab.selection_bounds
          offset = [s, e].sort[1]
          tab.insert(offset, output)
          tab.select(s+output.length, e+output.length)
        when :line
          if tab.cursor_line == tab.line_count-1
            tab.insert(tab.line_end(tab.cursor_line), "\n"+output)
          else
            tab.insert(tab.line_start(tab.cursor_line+1), output)
          end
        end
      end
    end
    
    def execute
      @output = nil
      tab = Redcar.current_tab
      input = get_input
      begin
        output = (@block ||= eval("Proc.new {\n"+@def[:command]+"\n}")).call
      rescue Object => e
        puts e
        puts e.message
      end
      p :output
      p output
      output ||= @output
      direct_output(output) if output
    end
  end
  
  class Menu
    INPUTS = [
              "None", "Document", "Line", "Word", 
              "Character", "Scope", "Nothing", 
              "Selected Text"
             ]
    OUTPUTS = [
               "Discard", "Replace Selected Text", 
               "Replace Document", "Insert As Text", 
               "Insert As Snippet", "Show As HTML",
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
        begin
          @data = YAML.load(IO.read("environment/menus.yaml"))
          @menus     = @data[:menus]
          @menu_defs = @data[:menu_defs]
          @commands  = @data[:commands]
        rescue
          @menus_user = []
          @menu_defs_user = {}
          @commands_user = {}
          @menus     = YAML.load(IO.read("environment/menus/menus.yaml"))
          @menu_defs = YAML.load(IO.read("environment/menus/menu_definitions.yaml"))
          @commands  = YAML.load(IO.read("environment/menus/commands.yaml"))
        end
        
        return [@menus, @menu_defs, @commands]
      end
      
      def save_menus
        File.open("environment/menus.yaml", "w") do |f|
          f.puts({ :menus => @menus, 
            :menu_defs => @menu_defs,
            :commands => @commands
          }.to_yaml)
        end
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
                if command_def[:activated_by] == :key_combination and
                    command_def[:activated_by_value]
                  keybinding = Redcar::KeyBinding.parse(
                                                        command_def[:activated_by_value])
                  this_name = command_def[:name].gsub(/_|-|\s/, "").downcase
                  Redcar.GlobalKeymap.class.class_eval do
                    keymap keybinding, "menu_#{this_name}".intern
                    define_method("menu_#{this_name}") do
                      command = Command.new(command_def)
                      begin
                        command.execute
                      rescue Object => e
                        puts e
                        puts e.message
                      end
                      # used to do this:
                      #      Redcar.process_command_error(id, e)
                    end
                  end
                end
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
