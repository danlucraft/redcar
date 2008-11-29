
module Redcar
  class ProjectTab < Tab
    TITLE = "Project"
    attr_accessor :store, :view, :directories

    def initialize(pane)
      @store = Gtk::TreeStore.new(Gdk::Pixbuf, String, String, String)
      @view = Gtk::TreeView.new(@store)
      renderer1 = Gtk::CellRendererPixbuf.new
      @renderer2 = Gtk::CellRendererText.new
#      @renderer2.editable = true
      @col1 = Gtk::TreeViewColumn.new
      @col1.title = "Icon"
      @col1.pack_start renderer1, false
      @col1.pack_start @renderer2, true
      @col1.set_attributes(renderer1, :pixbuf => 0)
      @col1.set_attributes(@renderer2, :text => 1)
      
      @view.append_column(@col1)
      @view.headers_visible = false
      @view.show
      
      @directories ||= []
      
      super(pane, @view, :scrolled? => true, :toolbar? => true)

      @gtk_sw.set_policy(Gtk::POLICY_NEVER, Gtk::POLICY_AUTOMATIC)
      self.title = TITLE
      @slot = bus('/redcar/project')
      icons_dir = Redcar.PLUGINS_PATH + '/project/icons/'
      @file_pic = Gdk::Pixbuf.new(icons_dir+"text-x-generic.png")
      @dir_pic = Gdk::Pixbuf.new(icons_dir+"folder.png")
      @image_pic = Gdk::Pixbuf.new(icons_dir+"gnome-mime-image.png")
      @ruby_pic = Gdk::Pixbuf.new(icons_dir+"ruby.png")
      GnomeVFS.init
      connect_signals
      ProjectPlugin.tab = self
    end
    
    def close
      super
      ProjectPlugin.tab = nil
    end
    
    def connect_signals
      @view.signal_connect(:row_activated) do |_, path, _|
        if @view.row_expanded?(path)
          @view.collapse_row(path)
        else
          open_row(path)
        end
      end
      
      @view.signal_connect(:row_expanded) do |_, iter, path|
        open_row(path) unless @ignore_row_expanded
      end
      
      @view.on_right_button_press do |_, gdk_event|
        # get the row and column
        unless @block_buttons
          path_array = @view.get_path_at_pos(gdk_event.x, gdk_event.y)
          popup_menu((path_array||[]).first, gdk_event)
        end
      end
    end
    
    def popup_menu(tree_path, button_event)
      menu_def = [
        ["Add Project", fn { AddProjectCommand.new.do }]
      ]
      
      if tree_path
        iter = @store.get_iter(tree_path)
        path = iter[2]
        menu_def += [
          ["Remove Project", fn { RemoveProjectCommand.new(path).do }],
          ["<hr />"],
          ["New File", fn { NewFileInProjectCommand.new(path).do }],
          ["Rename", fn { RenamePathInProjectCommand.new(path).do }]
        ]
      end
      
      ProjectTab.show_popup_menu(button_event, menu_def)
    end
    
    # expects an array like:
    # [["Copy", fn { p :copy_activated}], ...]
    #
    # if name is "<hr />" then a separator is inserted
    def self.show_popup_menu(button_event, item_definitions)
      menu = Gtk::Menu.new
      item_definitions.each do |item_definition|
        if item_definition[0] == "<hr />"
          menu.append(Gtk::SeparatorMenuItem.new)
        else
          menu_item = Gtk::MenuItem.new(item_definition[0])
          menu_item.signal_connect("activate") { item_definition[1].call }
          menu.append(menu_item)
        end
      end
      menu.show_all
      menu.popup(nil, nil, button_event.button, button_event.time)
    end

    def open_row(tree_path)
      iter = @store.get_iter(tree_path)
      if File.directory? iter[2]
        dir_tree_get(iter[2], iter)
        @ignore_row_expanded = true
        @view.expand_row(iter.path, false)
        @ignore_row_expanded = false
      else
        # TODO: make this use arrangements once they're working again
        pane = Redcar.win.panes.find {|pn| !pn.tabs.map(&:title).include?(TITLE)}
        OpenTab.new(iter[2], pane).do
      end
    end
    
    def dir_tree_get(path, parent_iter, &block)
      parent_iter.n_children.times do
        @store.remove parent_iter.first_child
      end
      files = Dir.glob(path+"/*")
      files.sort_by{ |f| ((File.directory? f) ? "a" : "z")+f }.each do |file|
        if block
          include_bool = block.call(file)
        else
          include_bool = true unless file =~ /~/ or file =~ /^\./ or file =~ /\.svn/
        end
        if include_bool
          iter = @store.append(parent_iter)
          initialize_iter_from_file(iter, path, file)
        end
      end
    end
    
    def initialize_iter_from_file(iter, path, file)
      filename = file[(path.length+1)..(file.length-1)]
      iter[1] = filename
      iter[2] = path+"/" + filename
      if File.directory? file
        iter[0] = @dir_pic
        dummy_iter = @store.append(iter)
        dummy_iter[1] = "[dummy row]"
        dummy_iter[2] = iter[2] + "/[dummy row]"
      else
        mime_type = GnomeVFS.get_mime_type(file)
        if mime_type
          case mime_type
          when /image/
            pic = @image_pic
          when /ruby/
            pic = @ruby_pic
          else
            pic = @file_pic
          end
        else
          pic = @file_pic
        end
        iter[0] = pic
      end
    end
    
    def add_directory(name, path, &block)
      iter = @store.append(nil)
      iter[0] = @dir_pic
      iter[1] = name
      iter[2] = path
      @directories << path
      self.dir_tree_get(path, iter, &block)
    end
    
    def remove_project(path)
      iter = @store.find_iter(2, path)
      iter = @store.get_iter(iter.path.to_s.split(":").first)
      remove_directory(iter[2])
    end
    
    def remove_directory(path)
      iter = @store.find_iter(2, path)
      @directories.delete(path)
      @store.remove(iter)
    end
    
    def new_file_at(path)
      iter = @store.find_iter(2, path)
      unless iter.has_child?
        iter = iter.parent
      end # iter now a directory
      open_row(iter.path)
      new_iter = @store.append(iter)
      new_iter[0] = @file_pic
      new_iter[1] = "unknown"
      new_iter[2] = iter[2] + "/unknown"
      FileUtils.touch(new_iter[2])
      @view.scroll_to_cell(new_iter.path, @col1, false, 0.5, 0.5)
      rename_path(new_iter[2])
    end
    
    def rename_path(path)
      iter = @store.find_iter(2, path)
      @renderer2.editable = true
      @view.set_cursor(iter.path, @col1, true)
      @edit_handler = @renderer2.signal_connect("edited") do |_, str_treepath, value|
        iter = @store.get_iter(str_treepath)
        old_filename = iter[2]
        dir = File.dirname(iter[2])
        new_filename = dir + "/#{value}"
        puts "rename: '#{old_filename}' ->  '#{new_filename}'"
        begin
          if old_filename != new_filename
            FileUtils.mv(old_filename, new_filename)
            initialize_iter_from_file(iter, dir, new_filename)
            if iter.has_child?
              dir_tree_get(iter[2], iter)
            end
          end
        rescue => e
          dialog = Gtk::MessageDialog.new(Redcar.win, 
                                Gtk::Dialog::DESTROY_WITH_PARENT,
                                Gtk::MessageDialog::QUESTION,
                                Gtk::MessageDialog::BUTTONS_CLOSE,
                                "Error renaming file from '#{old_filename}' to '#{new_filename}'.\n\nError message was:\n" +
                                e.message
                                )
          dialog.run
          dialog.destroy
        end									
        @renderer2.signal_handler_disconnect(@edit_handler)
        if @button_blocker_handler
          @view.signal_handler_disconnect(@button_blocker_handler)
        end
        @block_buttons = false
        @renderer2.editable = false
        @renderer2.signal_handler_disconnect(@edit_cancel_hander)
      end
      @button_blocker_handler = @view.on_button_press { false }
      @block_buttons = true
      @edit_cancel_handler = @renderer2.signal_connect("editing-canceled") do 
        @renderer2.signal_handler_disconnect(@edit_handler)
        if @button_blocker_handler
          @view.signal_handler_disconnect(@button_blocker_handler)
        end
        @block_buttons = false
        @renderer2.editable = false
        @renderer2.signal_handler_disconnect(@edit_cancel_handler)
      end
    end
    
    def clear
      @store.clear
      @directories.clear
    end
  end
end

