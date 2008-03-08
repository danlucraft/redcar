
module Redcar
  class Speedbar < Gtk::HBox
    extend FreeBASE::StandardPlugin
    
    attr_reader :visible
    
    def initialize
      super
      spacing = 5
      @visible = false
    end
    
    def build(&block)
      close
      collect_definition(block)
      build_widgets
      open
    end
    
    def clear_children
      children.each {|child| remove(child)}
    end
    
    def collect_definition(block)
      SpeedbarBuilder.clear
      SpeedbarBuilder.class_eval &block
    end
    
    def build_widgets
      add_button nil, :CLOSE, "Escape" do
        self.close
      end
      add_key("Escape") { self.close }
      SpeedbarBuilder.items.each do |item|
        send "add_#{item[0]}", *item[1..-1]
      end
    end
    
    def open
      Keymap.push_onto(win, "Speedbar")
      show_all
    end
    
    def close
      Keymap.remove_from(win, "Speedbar")
      hide if visible
      @visible = false
      bus("/redcar/keymaps/Speedbar").prune
      clear_children
    end
    
    def add_key(key, &block)
      com = Redcar::InlineCommand.new
      com.block = fn { block.call }
      keys = key.split("|").map(&:strip)
      keys.each do |key|
        bus("/redcar/keymaps/Speedbar/#{key}").data = com
      end
    end
    
    def add_label(text)
      label = Gtk::Label.new(text)
      label.set_padding(5, 1)
      pack_start(label, false)
    end
    
    def add_toggle(name, text, key)
      toggle = Gtk::CheckButton.new(text)
      add_key(key) { toggle.active = !toggle.active? } if key
      pack_start(toggle, false)
    end
    
    def add_textbox(name)
      e = Gtk::Entry.new
      # TODO: this should be set by preferences
      e.modify_font(Pango::FontDescription.new("Monospace 10"))
      pack_start(e)
    end
    
    def add_button(text, icon, key, block=nil, &blk)
      raise "Two blocks given to Speedbar#add_button" if block and blk
      label = Gtk::HBox.new
      label.pack_start(i=Gtk::Icon.get_image(icon, Gtk::IconSize::MENU)) if icon
      label.pack_start(l=Gtk::Label.new(text)) if text
      b = Gtk::Button.new
      b.relief = Gtk::RELIEF_NONE
      b.child = label
      b.signal_connect("clicked") do
        if block
          block.call
        elsif blk
          blk.call
        end
      end
      add_key(key) { b.activate } if key
      pack_start(b, false)
    end
    
    module SpeedbarBuilder
      def self.clear
        @items = []
      end

      def self.items
        @items
      end
      
      def self.label(text)
        @items << [:label, text]
      end
      
      def self.toggle(name, text, key)
        @items << [:toggle, name, text, key]
      end
      
      def self.textbox(name)
        @items << [:textbox, name]
      end
      
      def self.button(text, icon, key, &block)
        @items << [:button, text, icon, key, block]
      end
    end
  end
end

