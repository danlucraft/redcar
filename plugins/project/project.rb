
require 'gnomevfs'

module Redcar
  module Plugins
    module Project
      extend FreeBASE::StandardPlugin
      extend Redcar::PreferencesBuilder
      extend Redcar::MenuBuilder
      extend Redcar::CommandBuilder
      
      command "Project/Open" do |c|
        c.menu = "Project/Show"
        c.command %{
          new_tab = Redcar.new_tab(Redcar::ProjectTab)
          new_tab.focus
          Redcar.StatusBar.main = "Opened Project tab"
        }
      end
    end
  end
  
  class ProjectTab < Redcar::Tab
    def initialize(pane)
      @ts = Gtk::TreeStore.new(Gdk::Pixbuf, String, String)
      @tv = Gtk::TreeView.new(@ts)
      renderer1 = Gtk::CellRendererPixbuf.new
      renderer2 = Gtk::CellRendererText.new
      col1 = Gtk::TreeViewColumn.new
      col1.title = "Icon"
      col1.pack_start renderer1, false
      col1.pack_start renderer2, true
      col1.set_attributes(renderer1, :pixbuf => 0)
      col1.set_attributes(renderer2, :text => 1)
      
      @tv.append_column(col1)
      @tv.show
      super(pane, @tv, :scrolled => true, :toolbar? => true)
      self.name = "Project"
      @slot = ['/redcar/project']
      path = "/home/dan/projects/redcar"
      root_dir = $BUS['/system/properties/config/codebase/'].data+'/../plugins/project/icons/'
      p root_dir
      @file_pic = Gdk::Pixbuf.new(root_dir+"text-x-generic.png")
      @dir_pic = Gdk::Pixbuf.new(root_dir+"folder.png")
      @image_pic = Gdk::Pixbuf.new(root_dir+"gnome-mime-image.png")
      @ruby_pic = Gdk::Pixbuf.new(root_dir+"ruby.png")
      GnomeVFS.init
      add_directory("Redcar", path)
      connect_signals
    end
    
    def connect_signals
      @tv.signal_connect(:row_activated) do 
        if selected = @tv.selection.selected
          new_tab = Redcar.new_tab(Redcar::TextTab)
          new_tab.name = selected[1]
          new_tab.filename = selected[2]
          puts "loading file #{new_tab.filename}"
          new_tab.load
          new_tab.modified = false
          new_tab.focus
          new_tab.cursor = 0
        end
      end
    end
    
    def dir_tree_get(path, parent_iter, &block)
      files = Dir.glob(path+"/*")
      files.sort_by{|f| ((File.directory? f) ? "a" : "z")+f}.each do |file|
        if block
          include_bool = block.call(file)
        else
          include_bool = true unless file =~ /~/ or file =~ /^\./ or file =~ /\.svn/
        end
        if include_bool
          iter = @ts.append(parent_iter)
          filename = file[(path.length+1)..(file.length-1)]
          iter[1] = filename
          iter[2] = path+"/" + filename
          if File.directory? file
            iter[0] = @dir_pic
            dir_tree_get(path+"/"+filename, iter)
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
      iter = @ts.append(nil)
      iter[0] = @dir_pic
      iter[1] = name
      iter[2] = path
      self.dir_tree_get(path, iter, &block)
    end
  end
end
