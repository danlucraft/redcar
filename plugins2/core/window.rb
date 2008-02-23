
require 'gtk2'

module Redcar
  class Window < Gtk::Window
    extend FreeBASE::StandardPlugin
    
    def self.start(plugin)
      App.new_window
      plugin.transition(FreeBASE::RUNNING)
    end
    
    def self.stop(plugin)
      App.close_all_windows
      plugin.transition(FreeBASE::LOADED)
    end
    
    def initialize
      super("Redcar")
      build_widgets
      connect_signals
      attach_accel_groups
      show_all
    end
    
    def close
      App.close_window(self, true)
    end
    
    def panes
    end
    
    def unify_all
    end
    
    def new_tab(tab_class, focus = true)
    end
    
    def tabs
    end
    
    def active_tabs
    end
    
    def focussed_tab
    end
    
    def focus_previous_tab
    end
    
    def focus_tab(name)
    end
    
    def connect_signals
      signal_connect("destroy") do
        self.close
      end
      signal_connect('key-press-event') do |gtk_widget, gdk_eventkey|
        continue = Keymap.process(gdk_eventkey)
        # falls through to Gtk widget if nothing handles it
        continue
      end
    end
    
    def attach_accel_groups
      ag = Gtk::AccelGroup.new
      ag.connect(Gdk::Keyval::GDK_A, Gdk::Window::CONTROL_MASK,
                 Gtk::ACCEL_VISIBLE) {
        p "Hello World."
        true
      }

      add_accel_group(ag)
    end
  
    def build_widgets
      set_size_request(800, 600)
      gtk_menubar = Gtk::MenuBar.new 
      gtk_table = Gtk::Table.new(1, 4, false)
      bus["/gtk/window/table"].data = gtk_table
      bus["/gtk/window/menubar"].data = gtk_menubar
      gtk_table.attach(gtk_menubar,
                       # X direction            # Y direction
                       0, 1,                    0, 1,
                       Gtk::EXPAND | Gtk::FILL, 0,
                       0,                       0)
      gtk_toolbar = Gtk::Toolbar.new
      bus["/gtk/window/toolbar"].data = gtk_toolbar
      gtk_table.attach(gtk_toolbar,
                       # X direction            # Y direction
                       0, 1,                    1, 2,
                       Gtk::EXPAND | Gtk::FILL, 0,
                       0,                       0)
      gtk_panes = Gtk::HBox.new
      gtk_edit_view = Gtk::HBox.new
      bus["/gtk/window/editview"].data = gtk_edit_view
      bus["/gtk/window/panes_container"].data = gtk_panes
      gtk_edit_view.pack_start(gtk_panes)
      gtk_edit_view.pack_start(Gtk::TextView.new)
      gtk_table.attach(gtk_edit_view,
                   # X direction            # Y direction
                   0, 1,                    2, 3,
                   Gtk::EXPAND | Gtk::FILL, Gtk::EXPAND | Gtk::FILL,
                   0,      0)  
      gtk_status_hbox = Gtk::HBox.new
      bus["/gtk/window/statusbar"].data = gtk_status_hbox
      gtk_status1 = Gtk::Statusbar.new
      gtk_status2 = Gtk::Statusbar.new  
      bus["/gtk/window/statusbar/status1"].data = gtk_status1
      bus["/gtk/window/statusbar/status2"].data = gtk_status2
      gtk_status_hbox.pack_start(gtk_status1)
      gtk_status_hbox.pack_start(gtk_status2)
      gtk_table.attach(gtk_status_hbox,
                   # X direction            # Y direction
                   0, 1,                    3, 4,
                   Gtk::EXPAND | Gtk::FILL, Gtk::FILL,
                   0,      0)  
      add(gtk_table)
    end
  end
end
