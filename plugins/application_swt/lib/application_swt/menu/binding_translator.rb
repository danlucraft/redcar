module Redcar
  class ApplicationSWT
    class Menu
      module BindingTranslator
        MODIFIERS = %w(Cmd Ctrl Alt Shift)
        
        def self.platform_key_string(key_specifier)
          if key_specifier.is_a?(Hash)
            key_string = key_specifier[Core.platform]
          else
            key_string = key_specifier
          end
          key_string
        end

        def self.key(key_string)
          value = 0
          MODIFIERS.each do |modifier|
            if key_string =~ /\b#{modifier}\b/
              value += modifier_values[modifier]
            end
          end
          value += key_string[-1]
        end
        
        def self.key_string(key_event)
          modifiers = []
          modifier_values.each do |string, constant|
            if (key_event.stateMask & constant) != 0
              modifiers << string
            end
          end
          modifiers = modifiers.sort_by {|m| MODIFIERS.index(m) }
          if key_event.character == 0
            modifiers.join("+")
          else
            letter = java.lang.Character.new(key_event.keyCode).toString.upcase
            if modifiers.any?
              modifiers.join("+") << "+" << (pretty_letter(letter) || letter)
            else
              (pretty_letter(letter) || letter)
            end
          end
        end
        
        def self.matches?(key_string, key_string2)
          key_string.split("+").sort ==
            key_string2.split("+").sort
        end
        
        def self.pretty_letter(char_string)
          {"\r" => "Return"}[char_string]
        end
        
        private
        
        def self.modifier_values
          {
            "Cmd" => Swt::SWT::COMMAND,
            "Ctrl" => Swt::SWT::CTRL,
            "Alt" => Swt::SWT::ALT,
            "Shift" => Swt::SWT::SHIFT,
          }
        end
      end
    end
  end
end
