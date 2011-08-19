
module Redcar
  class Speedbar
    include Redcar::Model

    LabelItem   = ObservableStruct.new(:name, :text)
    ToggleItem  = ObservableStruct.new(:name, :text, :key, :listener, :value)
    TextBoxItem = ObservableStruct.new(:name, :listener, :value, :edit_view)
    ButtonItem  = ObservableStruct.new(:name, :text, :key, :listener)
    ComboItem   = ObservableStruct.new(:name, :items, :value, :editable, :listener)
    SliderItem  = ObservableStruct.new(:name, :value, :minimum, :maximum, :increment, :enabled, :listener)
    KeyItem     = ObservableStruct.new(:key, :listener)

    def self.items
      @items ||= []
    end

    def self.append_item(item)
      return if items.detect {|i| i.respond_to?(:name) and i.name == item.name }
      items << item
    end

    def self.close_image_path
      File.join(Redcar.icons_directory, "/close.png")
    end

    def self.define_item_finder(name)
      self.class_eval %Q{
        def #{name}
          __get_item(#{name.to_s.inspect})
        end
      }
    end

    def __get_item(name)
      item = __items.detect do |i|
        i.respond_to?(:name) and
          i.name.to_s == name
      end
      unless item
        raise "can't find item #{name}"
      end
      item
    end

    def __items
      @__items ||= self.class.items.map {|i| i.clone }
    end

    def __get_item_by_text_or_name(name)
      __items.detect {|i| (i.respond_to?(:text) and i.text == name) or i.name.to_s == name.to_s }
    end

    def __get_item_by_label(name)
      label = __items.detect {|i| i.is_a?(LabelItem) and (i.text == name or i.name.to_s == name.to_s)}
      if label
        index_of_label = __items.index(label)
        __items[index_of_label + 1]
      end
    end

    def self.label(name, text)
      append_item LabelItem.new(name, text)
      define_item_finder(name)
    end

    def self.toggle(name, text, key, value=false, &block)
      append_item ToggleItem.new(name, text, key, block, value)
      define_item_finder(name)
    end

    def self.textbox(name, value="", &block)
      append_item TextBoxItem.new(name, block, value)
      define_item_finder(name)
    end

    def self.button(name, text, key, &block)
      append_item ButtonItem.new(name, text, key, block)
      define_item_finder(name)
    end

    def self.combo(name, items=[], value=nil, editable=false,&block)
      append_item ComboItem.new(name, items, value, editable, block)
      define_item_finder(name)
    end

    def self.slider(name, value = 50, minimum = 0, maximum = 100, increment = 1, &block)
      append_item SliderItem.new(name, value, minimum, maximum, increment, true, block)
      define_item_finder(name)
    end

    def self.key(key, &block)
      append_item KeyItem.new(key, block)
    end

    def inspect
      "#<Speedbar #{__items.inspect}"
    end
  end
end
