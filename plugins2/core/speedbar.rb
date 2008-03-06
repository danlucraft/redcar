
module Redcar
  class Speedbar < Gtk::HBox
    extend FreeBASE::StandardPlugin
    
    attr_reader :visible
    
    def initialize
      super
      @visible = false
    end
    
    def build(&block)
      hide if visible
      clear_children
      collect_definition(block)
      build_widgets
      show_all
    end
    
    def clear_children
      children.each {|child| remove_child(child)}
    end
    
    def collect_definition(block)
      SpeedbarBuilder.clear
      SpeedbarBuilder.class_eval &block
    end
    
    def build_widgets
      add_button Gtk::Icon.get(:CLOSE), "Escape" do
        p :close_pressed
      end
      SpeedbarBuilder.items.each do |item|
        send "add_#{item[0]}", *item[1..-1]
      end
    end
    
    def add_label(text)
      label = Gtk::Label.new(text)
      label.set_padding(5, 1)
      pack_start(label, false)
    end
    
    def add_toggle(name, key)
      puts "add toggle to speedbar"
    end
    
    def add_textbox(name)
      e = Gtk::Entry.new
      # TODO: this should be set by preferences
      e.modify_font(Pango::FontDescription.new("Monospace 10"))
      pack_start(e)
    end
    
    def add_button(text, key, block=nil, &blk)
      raise "Two blocks given to Speedbar#add_button" if block and blk
      b = Gtk::Button.new(text)
      b.signal_connect("clicked") do
        if block
          block.call
        elsif blk
          blk.call
        end
      end
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
      
      def self.toggle(name, key)
        @items << [:toggle, name, key]
      end
      
      def self.textbox(name)
        @items << [:textbox, name]
      end
      
      def self.button(text, key, &block)
        @items << [:button, text, key, block]
      end
    end
  end
end

