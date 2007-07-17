
module Redcar
  class MenuEditTab < Tab
    def initialize(pane)
      main_hbox = Gtk::HBox.new
      super(pane, main_hbox, :scrolled => false)
      @glade = GladeXML.new("lib/glade/menu_edit_tab.glade", 
                            nil, 
                            "Redcar", 
                            nil, 
                            GladeXML::FILE) {|handler| method(handler)}
      dialog_vbox1 = @glade["dialog-vbox1"]
      dialog_vbox1.reparent(main_hbox)
#      main_hbox.pack_start(dialog_vbox1)
      main_hbox.show
      @glade["MenuEditDialog"].hide_all
      
      @treeview = @glade["treeview_menu"]
      @treeview.headers_visible = false
     # @treeview.reorderable = true
      @treestore = Gtk::TreeStore.new(String, String)
      @treeview.model = @treestore

      @menus = {}
      @menu_ids = []
      @item_ids = []
      load_menus
      display_menus
      
      renderer = Gtk::CellRendererText.new
      col = Gtk::TreeViewColumn.new("", renderer, :text => 0)
      @treeview.append_column(col)
      
      hide_edit_command
      hide_edit_menu
      selection = @treeview.selection
      selection.signal_connect("changed") do
        record_changes
        iter = selection.selected
        if iter
          selected_item(@treestore.get_value(iter, 1))
        end
        false
      end
      @treestore.signal_connect('row-deleted') do |_, _, _, _|
        reorder_menus
      end
      @glade["radio_shell"].signal_connect('clicked') do
        false
      end
      @glade["radio_inline"].signal_connect('clicked') do
        false
      end
      
      @stock_icons = ["none"]+Gtk::Stock.constants.sort
      
      hbox_icon = @glade["hbox13"]
      @combo_icon = Gtk::ComboBox.new
      @stock_icons.each do |constant_str|
        @combo_icon.append_text constant_str
      end
      hbox_icon.pack_end @combo_icon, false, true
      @combo_icon.show
      
      hbox_menu_icon = @glade["hbox17"]
      @combo_menu_icon = Gtk::ComboBox.new
      @stock_icons.each do |constant_str|
        @combo_menu_icon.append_text constant_str
      end
      hbox_menu_icon.pack_end @combo_menu_icon, false, true
      @combo_menu_icon.show
      
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
      hbox_combo_activated_by.pack_start @combo_activated_by, false, true
      Menu::ACTIVATIONS.each do |activation|
        @combo_activated_by.append_text activation
      end
      hbox_combo_activated_by.show_all
      
      hbox_sens = @glade["hbox_sensitive_to"]
      @combo_sensitive = Gtk::ComboBox.new
      @sensitive_options = ["Nothing"] + Sensitivity.names.map(&:to_title_string).sort
      @sensitive_options.each do |sty|
        @combo_sensitive.append_text sty
      end
      hbox_sens.pack_start @combo_sensitive
      hbox_sens.show_all
      
      sw_command = @glade["sw_command"]
      @sourceview = Redcar::SyntaxSourceView.new(:bundles_dir => "textmate/Bundles/",
                                                 :themes_dir  => "textmate/Themes/",
                                                 :cache_dir   => "cache/")
      sw_command.add(@sourceview)
      @sourceview.modify_font(Pango::FontDescription.new(TextTab.Preferences["Entry Font"]))
      @sourceview.set_theme(Theme.theme(TextTab.Preferences["Entry Theme"]))
      
      @sourceview.signal_connect("visibility-notify-event") do
        iter = @treeview.selection.selected
        if iter
          if @menu_ids.include? iter[1]
            hide_intro
            hide_edit_command
          elsif @item_ids.include? iter[1]
            hide_intro
            hide_edit_menu
          end
        end
      end
      
      gtk_keycomb = @glade["entry_key"]
      gtk_keycomb.signal_connect("key_press_event") do |_, eventkey|
        kb = Redcar.keystrokes.gdk_eventkey_to_keybinding(eventkey)
        gtk_keycomb.text = kb.to_s
        true
      end
      
      gtk_keycomb.signal_connect("key_release_event") do |_, eventkey|
        true
      end
      
      gtk_keycomb.signal_connect("focus-in-event") do |_, _|
        Redcar.keystrokes.disable
        false
      end
      gtk_keycomb.signal_connect("focus-out-event") do |_, _|
        Redcar.keystrokes.enable
        false
      end
      
      connect_drag_drop_callbacks
    end
    
    def load_menus
      @menu_tree, @menu_defs, @commands = Redcar::Menu.menus
      load_menus1(@menu_tree)
      @item_ids << "---"
    end
    
    def load_menus1(menus)
      menus.each do |menu|
        case menu
        when Hash # it's a menu
          uuid = menu.keys[0]
          @menu_ids << uuid
          items = menu.values[0]
          @menus[uuid] = menu[uuid]
          load_menus1(items)
        when String # it's a menu item
          uuid = menu
          @item_ids << uuid
        end
      end
    end

    def display_menus
      display_menus1(@menu_tree, nil)
    end
    
    def display_menus1(menus, parent_iter)
      menus.each do |menu|
        iter = @treestore.append(parent_iter)
        case menu
        when Hash # it's a menu
          uuid = menu.keys[0]
          if uuid == "---"
            name = "------"
          else
            name = @menu_defs[uuid]
            unless name
              puts "missing menu definition for #{uuid}"
              @treestore.remove(iter)
              next
            end
            name = name[:name]
          end
          iter[0] = name
          iter[1] = uuid
          items = menu.values[0]
          display_menus1(items, iter)
        when String # it's a menu item
          uuid = menu
          if uuid == "---"
            name = "------"
          else
            name = @commands[uuid]
            unless name
              puts "missing command definition for #{uuid}"
              @treestore.remove(iter)
              next
            end
            name = name[:name]
          end
          iter[0] = name
          iter[1] = uuid
        end
      end
    end
    
    def iter_for(uuid)
      @treestore.each do |_, _, iter|
        return iter if iter[1] == uuid
      end
    end
    
    def reorder_menus
      update_menu_tree
    end
    
    def on_cancel
      self.close
    end
    
    def on_ok
      on_apply
      on_cancel
    end
    
    def on_apply
      record_changes
      update_menu_tree
      Menu.menus = @menu_tree
      Menu.menu_defs = @menu_defs
      Menu.commands = @commands
      Menu.save_menus
      Menu.create_menus
    end
    
    def update_menu_tree
      @menu_tree = []
      top_iter = @treestore.iter_first
      update_menu_tree1(@menu_tree, top_iter)
      while top_iter.next!
        update_menu_tree1(@menu_tree, top_iter)
      end
    end
    
    def update_menu_tree1(arr, iter)
      uuid = iter[1]
      if @menu_ids.include? uuid
        submenu = []
        arr << {uuid => submenu}
        iter.n_children.times do |i|
          update_menu_tree1(submenu, iter.nth_child(i))
        end
      elsif @item_ids.include? uuid
        arr << uuid
      end
    end
    
    def record_changes
      if (uuid = @current_menu) != "---"
        if @menu_ids.include? uuid
          menu = @menu_defs[uuid]
          new_name = @glade["entry_menu_name"].text
          if menu[:name] != new_name
            iter_for(uuid)[0] = new_name
          end
          menu[:name] = new_name
          menu[:enabled] = @glade["check_menu_enabled"].active?
          menu[:visible] = @glade["check_menu_visible"].active?
          menu[:icon] = @combo_menu_icon.active_text
        elsif @item_ids.include? uuid
          menuitem = @commands[uuid]
          new_name = @glade["entry_name"].text
          if menuitem[:name] != new_name
            iter_for(uuid)[0] = new_name
          end
          menuitem[:name] = new_name
          menuitem[:enabled] = @glade["check_enabled"].active?
          menuitem[:visible] = @glade["check_visible"].active?
          menuitem[:tooltip] = @glade["entry_tooltip"].text
          menuitem[:command] = @sourceview.buffer.text
          if @glade["radio_inline"].active?
            menuitem[:type] = :inline
          else
            menuitem[:type] = :shell
          end
          menuitem[:input] = @combo_input1.active_text.to_title_symbol
          menuitem[:fallback_input] = @combo_input2.active_text.to_title_symbol
          menuitem[:output] = @combo_output.active_text.to_title_symbol
          menuitem[:activated_by] = @combo_activated_by.active_text.to_title_symbol
          menuitem[:scope_selector] = @glade["entry_scope_selector"].text
          menuitem[:icon] = @combo_icon.active_text
          menuitem[:activated_by_value] = @glade["entry_key"].text
          menuitem[:sensitive] = @combo_sensitive.active_text.to_title_symbol
        end
      end
    end
    
    def selected_item(uuid)
      if uuid == "---"
        show_sep
      else
        if @menu_ids.include? uuid
          show_menu(@menu_defs[uuid])
        elsif @item_ids.include? uuid
          show_menuitem(@commands[uuid])
        end
      end
      @current_menu = uuid
    end
    
    def show_sep
      show_intro
      hide_edit_menu
      hide_edit_command
    end
    
    def show_menuitem(menuitem)
      hide_intro
      hide_edit_menu
      show_edit_command
      @glade["entry_name"].text = menuitem[:name]||""
      @glade["entry_tooltip"].text = menuitem[:tooltip]||""
      @glade["check_enabled"].active = menuitem[:enabled]||false
      @glade["check_visible"].active = menuitem[:visible]||false
      command = menuitem[:command]||""
      @sourceview.show_all
      case menuitem[:type]
      when :inline
        @glade["radio_inline"].active = true
        @sourceview.set_grammar(SyntaxSourceView.grammar(:name => 'Ruby'))
      when :shell
        @glade["radio_shell"].active = true
        @sourceview.set_grammar(SyntaxSourceView.grammar(:first_line => command.split("\n")[0]))
      end
      @sourceview.buffer.text = command
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
      @combo_icon.active = @stock_icons.index(menuitem[:icon]||"none")
      @glade["entry_key"].text  = menuitem[:activated_by_value]||""
      sensitive = menuitem[:sensitive]
      if sensitive
        sensitive = sensitive.to_title_string
      else
        sensitive = "Nothing"
      end
      @combo_sensitive.active = @sensitive_options.index(sensitive)
    end
    
    def show_menu(menu)
      hide_intro
      hide_edit_command
      show_edit_menu
      @glade["entry_menu_name"].text = menu[:name]||""
      @glade["check_menu_enabled"].active = menu[:enabled]
      @glade["check_menu_visible"].active = menu[:visible]
      @combo_menu_icon.active = @stock_icons.index(menu[:icon]||"none")
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
    
    def connect_drag_drop_callbacks
      tv = @treeview
      ts = @treestore
      tv.enable_model_drag_source(Gdk::Window::BUTTON1_MASK,
                                  [['text/plain', 0, 0]],
                                  Gdk::DragContext::ACTION_MOVE)

      tv.enable_model_drag_dest([['text/plain', 0, 0]],
                                Gdk::DragContext::ACTION_MOVE)

      # define the callbacks
      tv.signal_connect "drag-data-get" do |_, context, data, info, time|
        tree_selection = tv.selection
        iter = tree_selection.selected
        text = ts.get_value(iter, 1) #uuid
        data.text = text
        #data.set(data.target, 8, text)
      end

      tv.signal_connect "drag-data-received" do |_, context, x, y, data, info, time|
        path, position = tv.get_dest_row(x, y)
        from_uuid = data.text
        if path
          to_iter = ts.get_iter(path)
        end
        success = false
        if @menu_ids.include? from_uuid
          if to_iter
            if @item_ids.include? to_iter[1]
              st = drop_menu_on_item(tv, position, data.text, to_iter)
              Gtk::Drag.finish(context, st, st, time)
            else # onto menu
              st = drop_menu_on_menu(tv, position, data.text, to_iter)
              Gtk::Drag.finish(context, st, st, time)
            end
          else
            drop_menu_on_end(tv, data.text)
            Gtk::Drag.finish(context, true, true, time)
          end
        elsif @item_ids.include? from_uuid
          if to_iter
            if @item_ids.include? to_iter[1]
              drop_item_on_item(tv, position, data.text, to_iter)
              Gtk::Drag.finish(context, true, true, time)
            else # onto menu
              drop_item_on_menu(tv, data.text, to_iter)
              Gtk::Drag.finish(context, true, true, time)
            end
          else
            Gtk::Drag.finish(context, false, false, time)
          end
        end
      end

      tv.signal_connect "drag-data-delete" do |_, context|
        tree_selection = tv.selection
        iter = tree_selection.selected
        ts.remove(iter)
      end
    end
    
    def drop_item_on_item(tv, position, uuid, to_iter)
      p :drop_item_on_item
      ts = tv.model
      if position == Gtk::TreeView::DROP_BEFORE or 
          position == Gtk::TreeView::DROP_INTO_OR_BEFORE
        new_iter = ts.insert_before(to_iter.parent, to_iter)
      elsif position == Gtk::TreeView::DROP_INTO_OR_AFTER or
          position == Gtk::TreeView::DROP_AFTER
        new_iter = ts.insert_after(to_iter.parent, to_iter)
      end
      if uuid == "---"
        name = "------"
      else
        name = @commands[uuid][:name]
      end
      new_iter[0] = name
      new_iter[1] = uuid
    end

    def drop_item_on_menu(tv, uuid, to_iter)
      p :drop_item_on_menu
      ts = tv.model
      new_iter = ts.append(to_iter)
      if uuid == "---"
        name = "------"
      else
        name = @commands[uuid][:name]
      end
      new_iter[0] = name
      new_iter[1] = uuid
    end
    
    def drop_menu_on_end(tv, uuid)
      ts = tv.model
      new_iter = ts.append(nil)
      new_iter[0] = @menu_defs[uuid][:name]
      new_iter[1] = uuid
      from_iter = tv.selection.selected
      copy_children(ts, from_iter, new_iter)
    end
    
    def parent_list(to_iter)
      if to_iter.parent
        [to_iter[1]] + parent_list(to_iter.parent)
      else
        [to_iter[1]]
      end
    end

    def drop_menu_on_menu(tv, position, uuid, to_iter)
      ancestors = parent_list(to_iter)
      if ancestors.include? uuid
        false
      else
        ts = tv.model
        if position == Gtk::TreeView::DROP_BEFORE
          new_iter = ts.insert_before(to_iter.parent, to_iter)
        elsif position == Gtk::TreeView::DROP_INTO_OR_BEFORE or
            position == Gtk::TreeView::DROP_INTO_OR_AFTER
          new_iter = ts.append(to_iter)
        else
          new_iter = ts.insert_after(to_iter.parent, to_iter)
        end
        new_iter[0] = @menu_defs[uuid][:name]
        new_iter[1] = uuid
        from_iter = tv.selection.selected
        copy_children(ts, from_iter, new_iter)
        true
      end
    end

    def drop_menu_on_item(tv, position, uuid, to_iter)
      ancestors = parent_list(to_iter)
      if ancestors.include? uuid
        false
      else
        ts = tv.model
        if position == Gtk::TreeView::DROP_BEFORE or 
            position == Gtk::TreeView::DROP_INTO_OR_BEFORE
          new_iter = ts.insert_before(to_iter.parent, to_iter)
        elsif position == Gtk::TreeView::DROP_INTO_OR_AFTER or
            position == Gtk::TreeView::DROP_AFTER
          new_iter = ts.insert_after(to_iter.parent, to_iter)
        end
        new_iter[0] = @menu_defs[uuid][:name]
        new_iter[1] = uuid
        from_iter = tv.selection.selected
        copy_children(ts, from_iter, new_iter)
        true
      end
    end


    def copy_children(ts, from_iter, to_iter)
      from_iter.n_children.times do |i|
        name = from_iter.nth_child(i)[0]
        uuid = from_iter.nth_child(i)[1]
        citer = ts.append(to_iter)
        citer[0] = name
        citer[1] = uuid
        copy_children(ts, from_iter.nth_child(i), citer)
      end
    end
    
    def selected_iter
      @treeview.selection.selected
    end
    
    def selected_menu_iter
      if @menu_ids.include? selected_uuid
        selected_iter
      else
        if selected_iter
          selected_iter.parent
        else
          nil
        end
      end
    end
    
    def selected_uuid
      (selected_iter||[])[1]
    end
    
    def selected_menu
      (selected_menu_iter||[])[1]
    end
    
    def on_new_command
      if selected_menu
        uuid = UUID.new
        command = {  
          :uuid => uuid, 
          :name => "New Command",
          :type => :inline,
          :fallback_input => :none,
          :input => :none,
          :output => :discard,
          :activated_by => :key_combination,
          :scope_selector => "",
          :command => "",
          :enabled => true,
          :visible => true,
          :tooltip => "",
          :icon => "none"      
        }
        @item_ids << uuid
        @commands[uuid] = command
        @menus[selected_menu] << uuid
        iter = @treestore.append(selected_menu_iter)
        iter[0] = "New Command"
        iter[1] = uuid
      end
    end
    
    def on_new_menu
      uuid = UUID.new
      menu = {
        :uuid => uuid,
        :name => "New Menu",
        :enabled => true,
        :visible => true
      }
      @menu_ids << uuid
      @menu_defs[uuid] = menu
      @menus[uuid] = []
      if selected_menu
        @menus[selected_menu] << uuid
        iter = @treestore.append(selected_menu_iter)
        iter[0] = "New Menu"
        iter[1] = uuid
      else
        iter = @treestore.append(nil)
        iter[0] = "New Menu"
        iter[1] = uuid
      end
    end
    
    def on_new_separator
      if selected_menu
        @menus[selected_menu] << "---"
        iter = @treestore.append(selected_menu_iter)
        iter[0] = "------"
        iter[1] = "---"
      end
    end
    
    def on_delete
      uuid = selected_uuid
      iter = selected_iter
      if @menu_ids.include? uuid
        @menus.delete(uuid)
        @menu_ids.delete(uuid)
      else
        @commands.delete(uuid)
        @item_ids.delete(uuid)
      end
      @treestore.remove(iter)
    end
    
    def on_edit_in_tab
      nt = Redcar.new_tab(Redcar::ButtonTextTab)
      nt.name = "Edit Command"
      nt.focus
      nt.button_label = "Finished Editing Command"
      nt.replace(@sourceview.buffer.text)
      nt.discard_changes = true
      nt.sourceview.grammar = @sourceview.grammar
      sourceview = @sourceview
      nt.on_button do
        sourceview.buffer.text = nt.contents
        nt.close
      end
    end
  end
end
