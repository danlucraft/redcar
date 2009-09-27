module Redcar
  class TestTab < Redcar::Tab
    attr_reader :name
    
    def initialize(pane, name)
      super(pane, Gtk::Label.new("foo"))
      @name = name
    end
  end
end
