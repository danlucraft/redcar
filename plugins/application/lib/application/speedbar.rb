
module Redcar
  class Speedbar
    include Redcar::Model
    
    LabelItem   = Struct.new(:text)
    ToggleItem  = Struct.new(:name, :text, :key, :listener, :value)
    TextBoxItem = Struct.new(:name, :listener, :value)
    ButtonItem  = Struct.new(:text, :key, :listener)
    KeyItem     = Struct.new(:key, :listener)
    
    attr_reader :__items, :__context
    
    def initialize(context)
      @__items = []
      @__context = context
      self.class.items.each {|i| @__items << i.clone }
    end
    
    def self.items
      @items ||= []
    end

    def self.append_item(item)
      items << item
    end
    
    def self.close_image_path
      File.join(Redcar.root, %w(plugins application icons close.png))
    end
    
    def self.define_value_finder(name)
      self.class_eval %Q{
        def #{name}
          __get_value_of(#{name.to_s.inspect})
        end
      }
    end
    
    def __get_value_of(name)
      item = __items.detect do |i| 
        i.respond_to?(:name) and
          i.name.to_s == name
      end
      unless item
        raise "can't find item #{name}"
      end
      item.value
    end
    
    def self.label(text)
      append_item LabelItem.new(text)
    end
    
    def self.toggle(name, text, key, value=false, &block)
      append_item ToggleItem.new(name, text, key, block, value)
      define_value_finder(name)
    end
    
    def self.textbox(name, value="", &block)
      append_item TextBoxItem.new(name, block, value)
      define_value_finder(name)
    end
    
    def self.button(text, key, &block)
      append_item ButtonItem.new(text, key, block)
    end
    
    def self.key(key, &block)
      append_item KeyItem.new(key, block)
    end
  end
end