module Redcar
  class Icon
    def self.get(name)
      icon = eval("Gtk::Stock::"+name.to_s.upcase)
#       Gtk::Image.new(icon, Gtk::IconSize::MENU)
    end
  end
end
      
