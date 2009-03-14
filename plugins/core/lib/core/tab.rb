
module Redcar
  # Redcar::Tab is the base class for all tabs used in Redcar.
  # It may be instantiated itself with an arbitrary Gtk widget
  # as a child, and has options to include a Gtk::Toolbar and
  # a scrollbars.
  class Tab
    def self.load #:nodoc:
      Sensitive.register(:tab, [:open_window, :new_tab, :close_tab]) do
        Redcar.win and Redcar.win.tabs.length > 0
      end
    end
    
    def self.start #:nodoc:
      @widget_to_tab = {}
    end
    
    def self.stop #:nodoc:
      @widget_to_tab.values.each do |tab|
        tab.close
      end
    end
    
    class << self
      attr_accessor :widget_to_tab
    end
    
    attr_accessor :pane, :label, :menu_label
    attr_reader :gtk_tab_widget, :gtk_nb_widget, :gtk_toolbar, :gtk_speedbar
    
    # Do not call this directly. Use Window#new_tab or 
    # Pane#new_tab instead:
    # 
    #   win.new_tab(Redcar::Tab, my_gtk_widget)
    #   pane.new_tab(Redcar::EditTab, my_gtk_widget, :scrolled? => true)
    #
    # Subclasses of Tab that override this method should call super and 
    # pass in the pane the tab is being created in and a Gtk widget that
    # the tab should contain. Options are 
    #   :toolbar?  => true|false
    #   :scrolled? => true|false
    # If :toolbar? is true the Tab will be equipped with a Toolbar and
    # if :scolled? is true the Gtk widget will be placed in a 
    # Gtk::ScrolledWindow.
    def initialize(pane, gtk_widget, options={})
      @pane = pane
      @gtk_tab_widget = gtk_widget
      @gtk_nb_widget = Gtk::VBox.new
      
      if options[:toolbar?]
        @gtk_toolbar = Gtk::Toolbar.new
        @gtk_nb_widget.pack_start(@gtk_toolbar, false)
        @gtk_toolbar.show_all
      end
      
      @gtk_speedbar = Redcar::SpeedbarDisplay.new # is an hbox
      @gtk_nb_widget.pack_end(@gtk_speedbar, false)
      
      if options[:scrolled?]
        @gtk_sw = Gtk::ScrolledWindow.new
        @gtk_sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
        @gtk_sw.add(gtk_widget)
        @gtk_nb_widget.pack_end(@gtk_sw)
        @gtk_sw.vscrollbar.signal_connect("value_changed") do 
          if gtk_widget.class.to_s == "SyntaxSourceView"
            gtk_widget.view_changed
          end
        end
      else
        @gtk_nb_widget.pack_end(gtk_widget)
      end
      
      @@tabcount ||= 0
      @@tabcount += 1
      @label = Gtk::NotebookLabel.new(self, "#new#{@@tabcount}", self.tab_icon) do
        CloseTab.new(self).do
      end
      @label_angle = :horizontal
      
      @menu_label = Gtk::Label.new("#new#{@@tabcount}")
      @menu_label.set_alignment(0, 0)
      @menu_label.show
      
      Tab.widget_to_tab[@gtk_nb_widget] = self
      
      @gtk_nb_widget.show
    end
    
    # Closes the tab by calling Pane#close_tab method on the tab's 
    # current pane.
    def close
      @pane.window.close_tab(self)
    end
    
    # Bring this tab to the forefront of it's pane, and make the tab's
    # widget grab the Gtk focus.
    def focus
      pane.focus_tab(self)
      on_focus
    end
    
    # Adjusts the angle of the label of the tab. angle should be one
    # of :bottom_to_top, :top_to_bottom, :horizontal
    def label_angle=(angle)
      case angle
      when :bottom_to_top
        @label.make_vertical
        @label.label.angle = 90
      when :top_to_bottom
        @label.make_vertical
        @label.label.angle = 270
      else
        @label.make_horizontal
        @label.label.angle = 0
      end
    end
    
    # Returns the tab's title (displayed on the tab's 'tab').
    def title
      @label.text
    end
    
    # Sets the tab's title (displayed on the tab's 'tab').
    def title=(text)
      @label.text = text
      @menu_label.text = text
    end

    # Moves this tab to dest_pane.
    def move_to_pane(dest_pane)
      @pane.move_tab(self, dest_pane)
      @pane = dest_pane
    end
    
    # Move the tab up one.
    def move_up
      nb = @pane.gtk_notebook
      new_ix = nb.page_num(@gtk_nb_widget)+1
      nb.reorder_child(@gtk_nb_widget, new_ix)
    end
    
    # Move the tab down one.
    def move_down
      nb = @pane.gtk_notebook
      new_ix = [nb.page_num(@gtk_nb_widget)-1, 0].max
      nb.reorder_child(@gtk_nb_widget, new_ix)
    end
    
    # This method is called when a Tab is created. The default
    # behaviour is to grab the focus for the Tab's Gtk widget.
    # Subclasses should override to replace this behaviour.
    def on_focus
      @gtk_tab_widget.grab_focus
    end
    
    # Called by initialize to get the icon for the Tab's 'tab'.
    def tab_icon
      nil
    end
    
    # Useful in testing. Subclasses should override with something 
    # more meaningful
    def contents_as_string
      @gtk_nb_widget.inspect
    end
    
    # Useful in testing. Subclasses should override with something 
    # more meaningful
    def visible_contents_as_string
      @gtk_nb_widget.inspect
    end
    
    # For some reason the standard inspect hangs, so we override.
    def inspect # :nodoc:
      "#<#{self.class}>"
    end
  end
end
