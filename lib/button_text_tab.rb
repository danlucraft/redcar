
module Redcar
  class ButtonTextTab < TextTab
    def initialize(pane)
      super(pane)
      @bb = Gtk::HButtonBox.new
      @bb.layout_style = Gtk::ButtonBox::START
      @button = Gtk::Button.new
      @bb.pack_start(@button, false, true)
      @tab_vbox.pack_start(@bb, false, true)
      @bb.show
      @button.show
    end
    
    def button_label=(name)
      @button.label = name
    end
    
    def on_button(&block)
      @block = block
      @button.signal_connect("clicked") do 
        block.call
      end
    end
  end
end
