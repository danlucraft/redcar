
module Redcar
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
    
    attr_accessor :gtk_tab_widget, :gtk_nb_widget, :pane, :label
    
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
          if gtk_widget.class == SyntaxSourceView
            gtk_widget.view_changed
          end
        end
      else
        @gtk_nb_widget.pack_end(gtk_widget)
      end
      
      @label = Gtk::NotebookLabel.new(self, "#new#{@pane.tabs.length}") do
        puts "closing tab:#{self.label.text}"
        self.close
      end
      @label_angle = :horizontal
      
      Tab.widget_to_tab[@gtk_nb_widget] = self
      
      @gtk_nb_widget.show
    end
    
    def close
      if @pane
        nb = @pane.gtk_notebook
        unless nb.destroyed?
          nb.remove_page(nb.page_num(@gtk_nb_widget))
          Tab.widget_to_tab.delete @gtk_nb_widget
        end
      end
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
    
    def title=(text)
      @label.text = text
    end
    
    def title
      @label.text
    end
    
    def move_to_pane(dest_pane)
      @pane.move_tab(self, dest_pane)
      @pane = dest_pane
    end
    
    def focus
      nb = @pane.gtk_notebook
      nb.set_page(nb.page_num(@gtk_nb_widget))
    end
  end
end
