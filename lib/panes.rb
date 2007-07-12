
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
    def self.context_menu=(menu)
      @@context_menu = menu
    end
    
    attr_accessor :notebook, :count, :tab_position, :tab_angle
    
    def initialize(panes, notebook, options={})
      options = process_params(options,
                               { :tab_position => :top,
                                 :tab_angle    => :horizontal })
      @panes = panes
      @notebook = notebook
      @count = 0
      @tab_hash = {}
      @tab_position = options[:tab_position]
      @tab_angle    = options[:tab_angle]
    end
    
    def tab_angle=(angle)
      @tab_angle = angle
      each do |tab|
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
    
    def tab_from_doc(doc)
      @tab_hash[doc]
    end
    
    def tab_hash
      @tab_hash
    end
    
    def first
      @tab_hash[@notebook.document_at_index(0)]
    end
    
    def last
      @tab_hash[@notebook.document_at_index(@count-1)]
    end
    
    def current
      @tab_hash[@notebook.document_at_index(@notebook.page)]
    end
    
    # returns an array of tabs, ordered by position in notebook
    def all
      @notebook.documents.map {|doc| @tab_hash[doc]}
    end
    
    def [](id)
      if id.is_a? Integer
        @tab_hash[@notebook.document_at_index(id)]
      elsif id.is_a? String
        @tab_hash[@notebook.documents.find{|doc|doc.title == id}]
      end
    end
    
    def count
      @tab_hash.values.length
    end
    
    def tabs
      self.to_a
    end
    
    include Enumerable
    
    def each
      all.each do |tab|
        yield tab
      end
    end
    
    def new_tab(type=TextTab, *args)
      tab = type.new(self, *args)
      tab.label_angle = @tab_angle
      tab
    end
    
    def add_tab(tab)
      @tab_hash[tab.doc] = tab
      tab.pane = self
      tab.label_angle = @tab_angle
      @notebook.add_document(tab.doc)
    end
    
    def remove_tab(tab)
      @tab_hash.delete(tab.doc)
      tab.pane = nil
      @notebook.remove_document(tab.doc)
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
