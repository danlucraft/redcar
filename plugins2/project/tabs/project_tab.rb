
module Redcar
  class ProjectTab < Tab
    TITLE = "Project"
    attr_accessor :store, :view, :directories

    def initialize(pane)
      @store = Gtk::TreeStore.new(Gdk::Pixbuf, String, String, String)
      @view = Gtk::TreeView.new(@store)
      renderer1 = Gtk::CellRendererPixbuf.new
      renderer2 = Gtk::CellRendererText.new
      col1 = Gtk::TreeViewColumn.new
      col1.title = "Icon"
      col1.pack_start renderer1, false
      col1.pack_start renderer2, true
      col1.set_attributes(renderer1, :pixbuf => 0)
      col1.set_attributes(renderer2, :text => 1)
      
      @view.append_column(col1)
      @view.headers_visible = false
      @view.show

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
        path_array = @view.get_path_at_pos(gdk_event.x, gdk_event.y)
        popup_menu((path_array||[]).first, gdk_event)
      end
    end
    
    def popup_menu(path, button_event)
      p path
      ProjectTab.show_popup_menu(button_event, 
        [
          ["", fn { p :foo }]
        ])
    end
    
    # expects an array like:
    # [["Copy", fn { p :copy_activated}], ...]
    #
    # if name is "<hr />" then a separator is inserted
    def self.show_popup_menu(button_event, item_definitions)
      menu = Gtk::Menu.new
      for item_definition in item_definitions
        if item_definition[0] == "<hr />"
          menu.append(Gtk::SeparatorItem.new)
        else
          menu_item = Gtk::MenuItem.new(item_definition[0])
          menu_item.signal_connect("activate") { item_definition[1].call }
          menu.append(menu_item)
        end
      end
      menu.show_all
      menu.popup(nil, nil, button_event.button, button_event.time)
    end

    def open_row(path)
      iter = @store.get_iter(path)
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
      end
    end
    
    def add_directory(name, path, &block)
      iter = @store.append(nil)
      iter[0] = @dir_pic
      iter[1] = name
      iter[2] = path
      @directories ||= []
      @directories << path
      self.dir_tree_get(path, iter, &block)
    end
    
    def clear
      @store.clear
      @directories.clear
    end
  end
end

