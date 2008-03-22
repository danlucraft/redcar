
module Redcar
  # Redcar::Tab is the base class for all tabs used in Redcar.
  class Tab
    extend FreeBASE::StandardPlugin
    
    def self.start(plugin)
      @widget_to_tab = {}
      plugin.transition(FreeBASE::RUNNING)
    end
    
    def self.stop(plugin)
      @widget_to_tab.values.each do |tab|
        tab.close
      end
      plugin.transition(FreeBASE::LOADED)
    end
    
    class << self
      attr_accessor :widget_to_tab
    end
    
    attr_accessor :pane, :label
    attr_reader :gtk_tab_widget, :gtk_nb_widget, :gtk_toolbar
    
    # Initializes a new Tab object. It must be given a Redcar::Pane 
    # (it cannot be created without a Pane) and a Gtk widget that it
    # contains. Options are 
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
      
      $tabcount ||= 0
      $tabcount += 1
      @label = Gtk::NotebookLabel.new(self, "#new#{$tabcount}") do
        self.close
      end
      @label_angle = :horizontal
      
      Tab.widget_to_tab[@gtk_nb_widget] = self
      
      @gtk_nb_widget.show
    end
    
    def close
      @pane.window.close_tab(self)
    end
    
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
    
    def title
      @label.text
    end
    
    def title=(text)
      @label.text = text
    end

    def move_to_pane(dest_pane)
      @pane.move_tab(self, dest_pane)
      @pane = dest_pane
    end
    
    def focus
      nb = @pane.gtk_notebook
      nb.set_page(nb.page_num(@gtk_nb_widget))
      @gtk_nb_widget.grab_focus
    end
    
    def move_up
      nb = @pane.gtk_notebook
      new_ix = nb.page_num(@gtk_nb_widget)+1
      nb.reorder_child(@gtk_nb_widget, new_ix)
    end
    
    def move_down
      nb = @pane.gtk_notebook
      new_ix = [nb.page_num(@gtk_nb_widget)-1, 0].max
      nb.reorder_child(@gtk_nb_widget, new_ix)
    end
  end
end
