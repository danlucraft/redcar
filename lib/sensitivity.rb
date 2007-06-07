
class Gtk::Widget
  def sensitize_to(name)
    Redcar::Sensitivity.set_sensitive_widget(self, name)
  end
  
  def desensitize
    Redcar::Sensitivity.desensitize_widget(self)
  end
end

module Redcar
  class Sensitivity
    def self.add(name, hooks, &block)
      @@sensitivities ||= {}
      @@sensitivities[name] ||= []
      unless $REDCAR_ENV["test"]
        hooks[:hooks].each do |hook|
          Redcar.hook(hook) do |obj| 
            Gtk.idle_add do
              should_be_active = block.call(obj)
              @@sensitivities[name].each do |gtkw|
                if should_be_active
                  gtkw.sensitive = true
                else
                  gtkw.sensitive = false
                end
              end
            end
          end
        end
      end
    end
    
    def self.set_sensitive_widget(gtkw, name)
      unless defined? @@sensitivities and @@sensitivities[name]
        puts "Trying to make a widget sensitive to a sensitivity that"+
          " doesn't exist! (#{name})"
        raise ArgumentError
      end
      @@sensitivities[name] << gtkw
      gtkw.sensitive = false
    end
    
    def self.desensitize_widget(gtkw)
      @@sensitivities.values.each {|wlist| wlist.delete(gtkw)}
      gtkw.sensitive = true
    end
  end
end
