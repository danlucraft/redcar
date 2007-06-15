
module Redcar
  class MenuEditDialog
    def initialize
      @glade = GladeXML.new("lib/glade/menu_edit_dialog.glade", 
                            nil, 
                            "Redcar", 
                            nil, 
                            GladeXML::FILE) {|handler| method(handler)}
      @treeview = @glade["treeview_menu"]
      @treestore = Gtk::TreeStore.new(String, String)
      @treeview.model = @treestore
      @menu_path_to_menu_hash = {}
      load_menus
      renderer = Gtk::CellRendererText.new
      renderer.text = "Boooo!"
      col = Gtk::TreeViewColumn.new("Last Name", renderer, :text => 0)
      @treeview.append_column(col)
      hide_edit_command
      hide_edit_menu
      @selection = @treeview.selection
      @selection.set_select_function do |_, _, path, is_sel|
        iter = @treestore.get_iter(path)
        puts "selected: #{@treestore.get_value(iter, 1).inspect}"
        selected_item(@treestore.get_value(iter, 1))
        true
      end
      @glade["radio_shell"].signal_connect('clicked') do
        switch_to_shell
      end
      @glade["radio_inline"].signal_connect('clicked') do
        switch_to_inline
      end
      
      hbox_input = @glade["hbox_input"]
      @combo_input1 = Gtk::ComboBox.new
      @combo_input2 = Gtk::ComboBox.new
      Menu::INPUTS.each do |input|
        @combo_input1.append_text input
        @combo_input2.append_text input
      end
      hbox_input.pack_start @combo_input1
      hbox_input.pack_start Gtk::Label.new("or"), false
      hbox_input.pack_start @combo_input2
      hbox_input.show_all
      
      hbox_output = @glade["hbox_output"]
      @combo_output = Gtk::ComboBox.new
      Menu::OUTPUTS.each do |output|
        @combo_output.append_text output
      end
      hbox_output.pack_start @combo_output
      hbox_output.show_all
      
      hbox_combo_activated_by =
        @glade["hbox_combo_activated_by"]
      @combo_activated_by = Gtk::ComboBox.new
      hbox_combo_activated_by.pack_start @combo_activated_by
      Menu::ACTIVATIONS.each do |activation|
        @combo_activated_by.append_text activation
      end
      hbox_combo_activated_by.show_all
    end
    
    def selected_item(menu_path)
      menu_hash = @menu_path_to_menu_hash[menu_path]
      puts "selected: #{menu_hash.inspect}"
      case menu_hash[:object] 
      when :menu
        show_menu(menu_hash)
      when :menuitem
        show_menuitem(menu_hash)
      end
    end
    
    def show_menuitem(menuitem)
      hide_intro
      hide_edit_menu
      show_edit_command
      @glade["entry_name"].text = menuitem[:name]||""
      @glade["entry_tooltip"].text = menuitem[:tooltip]||""
      @glade["check_enabled"].active = menuitem[:enabled]||""
      @glade["textview_command"].buffer.text = menuitem[:command]||""
      case menuitem[:type]
      when :inline
        @glade["radio_inline"].active = true
        switch_to_inline
      when :shell
        @glade["radio_shell"].active = true
        switch_to_shell
      end
      input = menuitem[:input]||:none
      fallback_input = menuitem[:fallback_input]||:none
      output = menuitem[:output]||:discard
      activated_by = menuitem[:activated_by]||:key_combination
      @combo_input1.active = Menu::INPUTS.index(input.to_title_string)
      @combo_input2.active = Menu::INPUTS.index(fallback_input.to_title_string)
      @combo_output.active = Menu::OUTPUTS.index(output.to_title_string)
      @combo_activated_by.active = 
        Menu::ACTIVATIONS.index(activated_by.to_title_string)
      @glade["entry_scope_selector"].text = menuitem[:scope_selector]||""
      icon = menuitem[:icon]
      @glade["entry_icon"].text = icon.to_s
    end
    
    def switch_to_shell
      @glade["label_inline"].hide
      @glade["label_shell"].show
    end
    
    def switch_to_inline
      @glade["label_inline"].show
      @glade["label_shell"].hide
    end
    
    def show_menu(menu)
      hide_intro
      hide_edit_command
      show_edit_menu
      @glade["entry_menu_name"].text = menu[:name]||""
      @glade["check_menu_enabled"].active = menu[:enabled]||""
    end
    
    def show_edit_menu
      @glade["frame_edit_menu"].show
    end
    
    def show_edit_command
      @glade["frame_edit_command"].show
    end
    
    def show_intro
      @glade["label_intro"].show
    end
    
    def hide_edit_menu
      @glade["frame_edit_menu"].hide
    end
    
    def hide_edit_command
      @glade["frame_edit_command"].hide
    end
    
    def hide_intro
      @glade["label_intro"].hide
    end
    
    def load_menus
      @menus = Redcar::Menu.menus
      load_menus1(@menus, nil, "")
    end
    
    def load_menus1(menus, parent_iter, menu_path)
      menus.each do |menu|
        iter = @treestore.append(parent_iter)
        iter[0] = menu[:name]
        new_menu_path = menu_path + menu[:name]
        iter[1] = new_menu_path
        @menu_path_to_menu_hash[new_menu_path] = menu
        if menu[:object] == :menu
          load_menus1(menu[:items], iter, new_menu_path)
        end
      end
    end
  end
end
