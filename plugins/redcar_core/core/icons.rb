module Redcar
  class Icon
    def self.get(name)
      icon = eval("Gtk::Stock::"+name.to_s.upcase)
    end
    def self.get_image(name, size=Gtk::IconSize::DND)
      Gtk::Image.new(self.get(name), size)
    end
  end
end
      
