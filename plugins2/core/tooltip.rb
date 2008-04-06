
module Redcar
  class Tooltip < Gtk::Window
    extend FreeBASE::StandardPlugin
    
    class << Tooltip
      attr_accessor :visible_tooltips
      attr_accessor :tooltip_handlers
    end
    
    def self.load(plugin)
      @visible_tooltips = []
      @tooltip_handlers = []
      plugin.transition(FreeBASE::LOADED)
    end
    
    def self.hide_all
      @visible_tooltips.each {|tt| tt.hide}
      @visible_tooltips = []
    end
    
    def self.clear_tooltips
      @visible_tooltips.each {|tt| tt.hide }
      @visible_tooltips.clear
      @tooltip_handlers.each do |th|
        if Redcar.win.signal_handler_is_connected?(th)
          Redcar.win.signal_handler_disconnect(th)
        end
      end
    end
    
    def initialize(x=50, y=50, text="[blank tooltip]")
      Tooltip.hide_all
      super(Gtk::Window::POPUP)
      set_border_width(1)
      label = Gtk::Label.new(text)
      add(label)
      move(x, y)
      counter = 0
      show_all
      Tooltip.visible_tooltips << self
      Tooltip.tooltip_handlers ||= []
      h1 = Redcar.win.signal_connect("button_press_event") do 
        Tooltip.clear_tooltips
      end
      h2 = Redcar.win.signal_connect("key_press_event") do 
        Tooltip.clear_tooltips
        false
      end
      Tooltip.tooltip_handlers << h1
      Tooltip.tooltip_handlers << h2
#       Thread.new do 
#         sleep 3
#         Tooltip.clear_tooltips
#       end
    end
    
  end
end
