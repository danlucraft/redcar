
module Redcar
  class << self
    attr_accessor :tab_length, :current_tab, :last_tab
    def current_tab=(tab)
      Redcar.last_tab = Redcar.current_tab
      Redcar.current_pane = tab.pane
      @current_tab = tab
    end
  end

  def self.tabs
    Redcar.current_pane
  end
  
  def self.Tabs
    Redcar.current_pane
  end
  
  class Tab
    attr_accessor :pane, :doc, :widget
    
    def initialize(pane, widget)
      @sw = Gtk::ScrolledWindow.new
      @sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
      @sw.add(widget)
      @widget = widget
      @doc = Gtk::MDI::Document.new(@sw, "#new#{pane.count}")
      @pane = pane
      @pane.notebook.add_document(@doc)
      @tab_num = pane.count
      pane.count += 1
      pane.tab_hash[@doc] = self
      @pane.notebook.show_all
      Redcar.event :new_tab, self
    end
        
    def position=(index)
      @pane.notebook.reorder_child(@sw, index)
    end
    
    def position
      @pane.notebook.index_of_document(@doc)
    end
      
    def focus
      Redcar.event :tab_focus, self do
        @pane.notebook.focus_document(@doc)
        Redcar.current_tab = self
      end
    end
    
    def name
      @doc.title
    end
    
    def name=(name)
      Redcar.event :tab_rename, self do
        @doc.title = name
      end
    end
    
    def close
      close!
    end
    
    def close!
      Redcar.event :tab_close, self do
        @pane.remove_tab(self)
      end
    end
    
    def has_focus?
      return true if @widget.focus?
      return true if defined? @@widgets and @widgets.find {|w| w.focus?}
    end
    
    attr_reader :label_angle
    
    def label_angle=(angle)
      @doc.label_angle = angle
    end
  end
  
end
