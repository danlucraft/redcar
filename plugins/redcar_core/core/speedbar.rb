# redcar/lib/speedbar
# D.B. Lucraft

module Redcar
  
  def self.speedbar
    Speedbar
  end
  
  class SpeedbarWrapper
    attr_accessor :widgets
    
    def initialize(barwidget, buttons, entries)
      @widgets = buttons + entries
      @barwidget = barwidget
      @buttons = {}
      @button_blocks = {}
      @name_widget = {}
      buttons.each do |barr|
        name   = barr[0]
        widget = barr[1]
        @buttons[name] = widget
        @name_widget[name] = widget
        widget.signal_connect('clicked') do
          @button_blocks[name].call
        end
      end
      @entries = {}
      entries.each do |earr|
        name   = earr[0]
        widget = earr[1]
        @entries[name] = widget
        @name_widget[name] = widget
        self.class.send(:define_method, name) do
          @entries[name].text
        end
        self.class.send(:define_method, (name.to_s+"=").intern) do |val|
          @entries[name].text = val.to_s
        end
      end
    end
    
    def on_button(name, &block)
      @button_blocks[name] = block
    end
    
    def press_button(name)
      @button_blocks[name].call
    end
    
    def widgets
      @name_widget.values
    end
    
    def focus(name)
      @name_widget[name].grab_focus
    end
    
    def show
      win.speedbar.pack_start(@barwidget)
      @barwidget.show_all
      @entries[@entries.keys[0]].grab_focus
      Redcar.event :speedbar_on, @barwidget
    end
    
    def close
      Redcar.event :speedbar_off, @barwidget
      win.speedbar.remove @barwidget
    end
  end
  
  class Speedbar
    class << self
      attr_accessor :alive
    end
  
    def self.build(options)
      hbox = Gtk::HBox.new
      
      # title
      if options[:title]
        label = Gtk::Label.new(options[:title])
        label.set_padding(5, 1)
        hbox.pack_start(label, false)
      end
      
      # text entry boxes:
      entries = []
      options[:entry] ||= []
      options[:entry].each do |entry|
        widget = Dialog.type_to_widget(entry)[0]
        if entry[:legend]
          hbox.pack_start(Gtk::Label.new(entry[:legend]))
        end
        entries << [entry[:name], widget]
        hbox.pack_start(widget)
      end
      
      # buttons
      buttons = []
      options[:buttons] ||= []
      options[:buttons].collect do |buttoninfo|
        what = Dialog.button_convert(buttoninfo)
        widget = Gtk::Button.new(what)
        buttons << [buttoninfo, widget]
        hbox.pack_start(widget, false)
      end
      
      SpeedbarWrapper.new(hbox, buttons, entries)
    end
    
    def self.close
      @speedbar.close
    end
  end
end
