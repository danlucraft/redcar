module Redcar
  class ApplicationSWT
    class Menu
      module BindingTranslator
        MODIFIERS = %w(Cmd Ctrl Alt Shift)
        
        def self.platform_key_string(key_specifier)
          if key_specifier.is_a?(Hash)
            key_string = key_specifier[Redcar.platform]
          else
            key_string = key_specifier
          end
          key_string.gsub("Escape", "")
          key_string.gsub("Space", "")
          key_string
        end

        def self.key(key_string)
          value = 0
          MODIFIERS.each do |modifier|
            if key_string =~ /\b#{modifier}\b/
              value += modifier_values[modifier]
            end
          end
          if key_string =~ /Escape$/
            value += Swt::SWT::ESC
          elsif key_string =~ /Space$/
            value += " "[0]
          elsif key_string =~ /(F\d+)/
            value += Swt::SWT.const_get $1
          elsif key_string =~ /Page Up$/
            value += Swt::SWT::PAGE_UP
          elsif key_string =~ /Page Down$/
            value += Swt::SWT::PAGE_DOWN
          elsif key_string =~ /(Right|Left|Up|Down)/
            value += Swt::SWT.const_get 'ARROW_'+$1.upcase
          elsif key_string =~ /Tab/
            value += Swt::SWT::TAB
          elsif key_string =~ /Home$/
            value += Swt::SWT::HOME
          elsif key_string =~ /End$/
            value += Swt::SWT::END
          else
            value += key_string[-1]
          end
        end
        
        def self.modifiers(key_event)
          modifiers = []
          modifier_values.each do |string, constant|
            if (key_event.stateMask & constant) != 0
              modifiers << string
            end
          end
          modifiers = modifiers.sort_by {|m| MODIFIERS.index(m) }
        end
        
        def self.key_string(key_event)
          modifiers = modifiers(key_event)
          if key_event.character == 0
            modifiers.join("+")
          else
            letter = java.lang.Character.new(key_event.character).toString.upcase # key_event.keyCode)
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
            "Cmd"   => Swt::SWT::COMMAND,
            "Ctrl"  => Swt::SWT::CTRL,
            "Alt"   => Swt::SWT::ALT,
            "Shift" => Swt::SWT::SHIFT,
          }
        end
      end
    end
  end
end
