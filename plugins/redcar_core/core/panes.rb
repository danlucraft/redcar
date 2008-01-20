
module Redcar  
  class << self
    attr_accessor :last_pane, :arrangments

    def new_tab(type=TextTab)
      Redcar.current_pane.new_tab(type)
    end
    
    def current_pane=(pane)
      Redcar.last_pane = Redcar.current_pane
      @current_pane = pane
    end
    
    def current_pane
      return @current_pane if @current_pane
      ct = Redcar.current_tab
      ct.pane if ct
    end
  end
  
  class Pane
    extend Redcar::ContextMenuBuilder
    extend Redcar::CommandBuilder
    
    context_menu_separator "Panes"
    
    command "Panes/Alignment/Top" do |c|
      c.context_menu = "Pane/Alignment/Top"
      c.command %q{ 
        pane.tab_position = :top
        pane.tab_angle    = :horizontal
      }
    end
    
    command "Panes/Alignment/Left" do |c|
      c.context_menu = "Pane/Alignment/Left"
      c.command %q{ 
        pane.tab_position = :left
        pane.tab_angle    = :bottom_to_top
      }
    end
    
    command "Panes/Alignment/Right" do |c|
      c.context_menu = "Pane/Alignment/Right"
      c.command %q{ 
        pane.tab_position = :right
        pane.tab_angle    = :top_to_bottom
      }
    end
    
    command "Panes/Alignment/Bottom" do |c|
      c.context_menu = "Pane/Alignment/Bottom"
      c.command %q{ 
        pane.tab_position = :bottom
        pane.tab_angle    = :horizontal
      }
    end
    
    class << self
      def panes
        Redcar.current_window.panes
      end
      def context_menu=(menu)
        @@context_menu = menu
      end
    end
    
    attr_accessor :notebook, :count, :tab_position, :tab_angle
    
    def initialize(panes, notebook, options={})
      options = process_params(options,
                               { :tab_position => :top,
                                 :tab_angle    => :horizontal })
      @panes = panes
      @notebook = notebook
      @count = 0
      @tab_position = options[:tab_position]
      @tab_angle    = options[:tab_angle]
    end
    
    def tab_angle=(angle)
      @tab_angle = angle
      each_tab do |tab|
        tab.label_angle = angle
      end
    end
    
    def tab_position=(position)
      @tab_position = position
      case position
      when :bottom
        @notebook.set_tab_pos(Gtk::POS_BOTTOM)
      when :left
        @notebook.set_tab_pos(Gtk::POS_LEFT)
      when :right
        @notebook.set_tab_pos(Gtk::POS_RIGHT)
      else
        @notebook.set_tab_pos(Gtk::POS_TOP)
      end
    end
    
    def split_horizontal
      Redcar.event :split_horizontal, self
      paned, pane_right = @panes.split_horizontal(@notebook)
      pane_right.notebook.show
      return paned, self, pane_right
    end
    
    def split_vertical
      Redcar.event :split_vertical, self
      paned, pane_bottom = @panes.split_vertical(@notebook)
      pane_bottom.notebook.show
      return paned, self, pane_bottom
    end
    
    def unify
      @panes.unify(@notebook)
    end
    
    def first
      Tab.widget_to_tab[@notebook.get_nth_page(0)]
    end
    
    def last
      Tab.widget_to_tab[@notebook.get_nth_page(n_pages-1)]
    end
    
    def current
      Tab.widget_to_tab[@notebook.get_nth_page(@notebook.page)]
    end
    
    # returns an array of tabs, ordered by position in notebook
    def tabs
      returning(tabs = []) do
        0.upto(n_pages-1) do |i| 
          tabs << Tab.widget_to_tab[@notebook.get_nth_page(i)]
        end
      end
    end
    
    def n_pages
      @notebook.n_pages
    end
    
    def [](id)
      if id.is_a? Integer
        @tab_hash[@notebook.get_nth_page(id)]
      elsif id.is_a? String
        @tab_hash[all.find{|tab| tab.title == id}]
      end
    end
    
    include Enumerable
    
    def each_tab
      tabs.each do |tab|
        yield tab
      end
    end
    
    def new_tab(type=TextTab, *args)
      returning tab = type.new(self, *args) do
        tab.label_angle = @tab_angle
      end
    end
    
    def add_tab(tab)
      tab.label_angle = @tab_angle
      @notebook.append_page(tab.nb_widget, tab.label)
      @notebook.set_tab_reorderable(tab.nb_widget, true)
      @notebook.set_tab_detachable(tab.nb_widget, true)
    end
    
    def remove_tab(tab)
      @notebook.remove(tab.nb_widget)
    end
    
    def migrate_tab(tab, dest_pane)
      self.remove_tab(tab)
      dest_pane.add_tab(tab)
    end
    
    def panes
      @panes
    end
  end
end
