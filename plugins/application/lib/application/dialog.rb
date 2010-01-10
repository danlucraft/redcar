module Redcar
  class Application
    class Dialog
      # Prompt the user with an open file dialog. Returns a path.
      def self.open_file(window, options)
        Redcar.gui.dialog_adapter.open_file(window, options)
      end
      
      # Prompt the user with an open directory dialog. Returns a path.
      def self.open_directory(window, options)
        Redcar.gui.dialog_adapter.open_directory(window, options)
      end

      # Prompt the user with an save file dialog. Returns a path.
      def self.save_file(window, options)
        Redcar.gui.dialog_adapter.save_file(window, options)
      end
      
      # Show a message to the user. Requires a message and
      # options can be:
      #
      #  :type should be one of available_message_box_types
      #  :buttons should be one of available_message_box_button_combos
      #
      # It will return a symbol representing the button the user clicked on:
      #
      # For example:
      #
      # >> Application::Dialog.message_box(win, "YO!", :type => :info, 
      # >>                                             :buttons => :yes_no_cancel)
      # => :yes
      #
      # @param [Window]
      # @param [String] the message
      # @param [Hash] options
      # @return [Symbol] the button the user clicked on.
      def self.message_box(window, text, options={})
        if buttons = options[:buttons] and !available_message_box_button_combos.include?(buttons)
          raise "option :buttons must be in #{available_message_box_button_combos.inspect}"
        end
        if type = options[:type] and !available_message_box_types.include?(type)
          raise "option :type must be in #{available_message_box_button_types.inspect}"
        end
        Redcar.gui.dialog_adapter.message_box(window, text, options)
      end
      
      # Returns the list of valid button combos that can be passed
      # as an option to message_box.
      def self.available_message_box_button_combos
        Redcar.gui.dialog_adapter.available_message_box_button_combos
      end
      
      # Returns the list of valid message box types that can be passed
      # as an option to messsage_box
      def self.available_message_box_types
        Redcar.gui.dialog_adapter.available_message_box_types
      end
    end
  end
end