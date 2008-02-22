

module Redcar
  
class Window
  
  # API methods
   def close
     Redcar::App.close_window(self)
   end
  
#   def panes
#   end
  
#   def unify_all
#   end
  
#   def new_tab(tab_class, focus = true)
#   end
  
#   def tabs
#   end
  
#   def active_tabs
#   end
  
#   def focussed_tab
#   end
  
#   def focus_previous_tab
#   end
  
#   def focus_tab(name)
#   end
  
  # API end
  
  def connect_signals
    signal_connect("destroy") do
      self.close
    end
  end
  
  def build_widgets
    set_size_request(800, 600)
    @show_objects = []
    @notebooks = []
    paned = Gtk::HPaned.new
    Redcar.menubar = Gtk::MenuBar.new
    table = Gtk::Table.new(1, 4, false)
    table.attach(Redcar.menubar,
                 # X direction            # Y direction
                 0, 1,                    0, 1,
                 Gtk::EXPAND | Gtk::FILL, 0,
                 0,                       0)
    
    toolbar_widget = Gtk::Toolbar.new
    Redcar::Toolbar.set_toolbar_widget("Main", toolbar_widget)
    
    table.attach(Redcar::Toolbar.get_toolbar_widget("Main"),
                 # X direction            # Y direction
                 0, 1,                    1, 2,
                 Gtk::EXPAND | Gtk::FILL, 0,
                 0,                       0)
    hpaned = Gtk::HPaned.new
    edit_view = Gtk::VBox.new
    edit_view.pack_start(hpaned)
    @speedbar = Gtk::VBox.new
    edit_view.pack_start(@speedbar, false)
    @show_objects << @speedbar
    @show_objects << hpaned
    table.attach(edit_view,
                 # X direction            # Y direction
                 0, 1,                    2, 3,
                 Gtk::EXPAND | Gtk::FILL, Gtk::EXPAND | Gtk::FILL,
                 0,      0)    
    @status_hbox = Gtk::HBox.new
    $BUS['/redcar/gtk/layout/status_hbox'].data = @status_hbox
    
    @status1 = Gtk::Statusbar.new
    @status2 = Gtk::Statusbar.new
    Redcar::StatusBar.statusbar1 = @status1
    Redcar::StatusBar.statusbar2 = @status2
    @status_hbox.pack_start(@status1)
    @status_hbox.pack_start(@status2)
    @show_objects << @status_hbox
    @show_objects << @status1
    @show_objects << @status2
    table.attach(@status_hbox,
                 # X direction            # Y direction
                 0, 1,                    3, 4,
                 Gtk::EXPAND | Gtk::FILL, Gtk::FILL,
                 0,      0)  
    n = @notebook
    
    add(table)
      
    # setup panes business:-
    @paneds = [hpaned]
    @top_paned = hpaned
    notebook = make_new_notebook
    hpaned.add(notebook)
    @show_objects << notebook
    @show_objects << hpaned
    @top_pane_done = false
    pane = Redcar::Pane.new(self, notebook)
    @panes = [pane]
    @notebook_to_pane = {}
    @notebook_to_pane[notebook] = pane
#     Redcar.last_pane = Redcar.current_pane
#     Redcar.current_pane = pane
    
    @show_objects << Redcar.menubar
    @show_objects << table
    @show_objects << self
  end
end

end
