
module Redcar
  class << self
    attr_accessor :tab_length, :current_tab, :last_tab
    def current_tab=(tab)
      Redcar.last_tab = Redcar.current_tab
      Redcar.current_pane = tab.pane
      @current_tab = tab
    end
    
    # Allows Redcar.tab["name.rb"] and Redcar.tab[3]
    define_method_bracket :tab do |id|
      case id
      when Integer
        win.all_tabs[id]
      when String
        win.all_tabs.find {|tab| tab.name == id}
      end
    end
  end

  def self.tabs
    Redcar.current_pane
  end
  
  def self.Tabs
    Redcar.current_pane
  end

  # A simple notebook "label" (HBox container) with a text label and 
  # a close button.
  class NotebookLabel < Gtk.HBox
    type_register
    
    # Creates a new notebook label labeled with the text *str*.
    def initialize(tab, str='')
      super()
      @tab = tab
      self.homogeneous = false
      self.spacing = 4
      
      @box = Gtk.HBox.new
      
      @label = Gtk.Label.new(str)
      
      @button = Gtk.Button.new
      @button.set_border_width(0)
      @button.set_size_request(22, 22)
      @button.set_relief(Gtk.RELIEF_NONE)
      
      image = Gtk.Image.new
      image.set(:'gtk-close', Gtk.IconSize.MENU)
      @button.add(image)
      
      pack_start(@box)
      
      @box.pack_start(@label, true, false, 0)
      @box.pack_start(@button, false, false, 0)
      
      @button.signal_connect('clicked') do |widget, event|
        @tab.close if @tab.open
      end
      show_all
    end
    
    attr_reader :label, :button
    
    def make_horizontal
      unless @box.is_a? Gtk.HBox
        self.remove @box
        @box.remove @label
        @box.remove @button
        @box = Gtk.HBox.new
        @box.pack_start(@label, true, false, 0)
        @box.pack_start(@button, false, false, 0)
        pack_start @box
        @box.show
      end
    end
      
    def make_vertical
      unless @box.is_a? Gtk.VBox
        self.remove @box
        @box.remove @label
        @box.remove @button
        @box = Gtk.VBox.new
        @box.pack_start(@label, true, false, 0)
          @box.pack_start(@button, false, false, 0)
        pack_start @box
        @box.show
      end
    end
    
    def text
      @label.text
    end
    
    def text=(t)
      @label.text = t
    end
  end
  
  class Tab
    class << self
      attr_accessor :widget_to_tab
    end
    
    attr_accessor :doc, :widget, :nb_widget, :label, :open, :toolbar
    
    def initialize(inpane, widget, options={})
      @widget = widget
      @nb_widget = Gtk.VBox.new
      
      if options[:toolbar?]
        @toolbar = Gtk.Toolbar.new
        @nb_widget.pack_start(@toolbar, false)
        @toolbar.show_all
      end
      
      if options[:scrolled]
        @sw = Gtk::ScrolledWindow.new
        @sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
        @sw.add(widget)
        @nb_widget.pack_end(@sw)
      else
        @nb_widget.pack_end(widget)
      end
      
      @label_text = "#new#{inpane.n_pages}"
      @label_angle = :horizontal
      @label = NotebookLabel.new(self, @label_text)
      inpane.notebook.append_page(@nb_widget, @label)
      inpane.notebook.set_tab_reorderable(@nb_widget, true)
      inpane.notebook.set_tab_detachable(@nb_widget, true)
      inpane.notebook.show_all if win.visible?
      Redcar.event :new_tab, self
      Tab.widget_to_tab ||= {}
      Tab.widget_to_tab[@nb_widget] = self
      @open = true
    end
        
    def pane
      win.pane_from_tab(self)
    end
    
    def focus
      Redcar.event :tab_focus, self do
        nb = pane.notebook
        nb.set_page(nb.page_num(@nb_widget))
        Redcar.current_tab = self
      end
    end
    
    def name
      @label_text
    end
    
    def name=(name)
      Redcar.event :tab_rename, self do
        @label_text = name
        @label.text = name
      end
    end
    
    def close
      close!
    end
    
    def close!
      Redcar.event :tab_close, self do
        nb = pane.notebook
        nb.remove_page(nb.page_num(@nb_widget))
        Tab.widget_to_tab.delete @nb_widget
      end
      @open = false
    end
    
    def has_focus?
      return true if @widget.focus?
      return true if defined? @@widgets and @widgets.find {|w| w.focus?}
    end
    
    attr_reader :label_angle
    
    def set_label(text, angle)
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
    
    def label_angle=(angle)
      set_label(@label_text, angle)
    end
      
    def selected?
      nil
    end
    
    def any_undo?
      nil
    end
  end
end
