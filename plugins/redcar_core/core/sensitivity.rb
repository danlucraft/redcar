
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
    def self.names
      @@sensitivities.keys
    end
    
    def self.add(name, hooks, &block)
      @@sensitivities ||= {}
      @@sensitivities[name] ||= []
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
            false
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

module Redcar
  Sensitivity.add(:open_text_tabs?, 
                  :hooks => [:after_tab_close, :after_new_tab]) do 
    !window.all_tabs.empty?
  end
  
  Sensitivity.add(:open_tabs?, 
                  :hooks => [:after_tab_close, :after_new_tab]) do 
    !window.all_tabs.empty?
  end
  
  Sensitivity.add(:unsaved_text_tabs?,
                  :hooks => [
                             :after_new_tab,
                             :after_close_tab,
                             :after_save_tab
                             ]) do
    window.all_tabs.find do |tab| 
      tab.modified? if tab.respond_to? :modified?
    end
  end
  
  Sensitivity.add(:text_selected?,
                  :hooks => [:after_select, :after_focus, 
                             :tab_focus, :tab_clicked, :tab_changed]) do
    Redcar.current_tab and Redcar.current_tab.selected?
  end
  
  Sensitivity.add(:undo_info?,
                  :hooks => [:tab_changed, :after_tab_focus]) do
    if Redcar.current_tab.is_a? TextTab
      Redcar.current_tab.buffer.can_undo?
    end
  end
  
  Sensitivity.add(:current_tab_is_text_tab?,
                  :hooks => [:after_tab_focus, :after_new_tab, 
                             :after_close_tab]) do
    Redcar.current_tab.is_a? TextTab
  end
  
  Sensitivity.add(:can_undo?,
                  :hooks => [:tab_changed, :after_tab_focus]) do
    if Redcar.current_tab.is_a? TextTab
      Redcar.current_tab.buffer.can_undo?
    end
  end
  
  Sensitivity.add(:can_redo?,
                  :hooks => [:tab_changed, :after_tab_focus]) do
    if Redcar.current_tab.is_a? TextTab
      Redcar.current_tab.buffer.can_redo?
    end
  end
  
  Sensitivity.add(:can_paste?,
                  :hooks => [:after_new_tab, :after_tab_close, 
                             :after_focus, :after_clipboard_added]) do
    !Clipboard.to_a.empty? and window.focussed_tab.respond_to? :paste
  end
  
  Sensitivity.add(:has_grammar?,
                  :hooks => [:after_new_tab, :after_tab_close, 
                             :after_focus, :after_clipboard_added]) do
    window.focussed_tab.respond_to? :grammar=
  end
end
