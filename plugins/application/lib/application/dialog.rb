module Redcar
  class Application
    class Dialog
      # Is the application currently showing a modal dialog?
      def self.in_dialog?
        @in_dialog
      end
      
      # Do not call
      def self.in_dialog
        @in_dialog = true
        r = yield
        @in_dialog = false
        r
      end
      
      # Prompt the user with an open file dialog. Returns a path.
      def self.open_file(options)
        in_dialog { Redcar.gui.dialog_adapter.open_file(options) }
      end
      
      # Prompt the user with an open directory dialog. Returns a path.
      def self.open_directory(options)
        in_dialog { Redcar.gui.dialog_adapter.open_directory(options) }
      end

      # Prompt the user with an save file dialog. Returns a path.
      def self.save_file(options)
        in_dialog { Redcar.gui.dialog_adapter.save_file(options) }
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
      # >> Application::Dialog.message_box("YO!", :type => :info, 
      # >>                                        :buttons => :yes_no_cancel)
      # => :yes
      def self.message_box(text, options={})
        if buttons = options[:buttons] and !available_message_box_button_combos.include?(buttons)
          raise "option :buttons must be in #{available_message_box_button_combos.inspect}"
        end
        if type = options[:type] and !available_message_box_types.include?(type)
          raise "option :type must be in #{available_message_box_button_types.inspect}"
        end
        in_dialog { Redcar.gui.dialog_adapter.message_box(text, options) }
      end
      
      # Returns the list of valid button combos that can be passed
      # as an option to message_box.
      def self.available_message_box_button_combos
        in_dialog { Redcar.gui.dialog_adapter.available_message_box_button_combos }
      end
      
      # Returns the list of valid message box types that can be passed
      # as an option to message_box
      def self.available_message_box_types
        in_dialog { Redcar.gui.dialog_adapter.available_message_box_types }
      end
      
      # Show a dialog containing a text entry box to the user, and blocks
      # until they dismiss it.
      #
      # If a block is given, the block is considered an input validator. A return
      # value of nil from the block means the value is valid, a return value
      # of a String from the block means the value is invalid, and the returned
      # String will be displayed as an error message.
      #
      # Example:
      #
      # Application::Dialog.input("Number", "Please enter a big number", "101") do |text|
      #	  if text.to_i > 100
      #	    nil
      #	  else
      #	    "must be bigger than 100"
      #	  end
      #	end
      #
      # The return value is a hash containing :button and :value.
      def self.input(title, message, initial_value="", &validator)
        in_dialog { Redcar.gui.dialog_adapter.input(title, message, initial_value, &validator) }
      end

      # Show a dialog containing a password entry box to the user, and blocks
      # until they dismiss it.
      #
      # The return value is a hash containing :button and :value.
      def self.password_input(title, message)
        in_dialog { Redcar.gui.dialog_adapter.password_input(title, message) }
      end
      
      # Shows a tool tip to the user, at the cursor location.
      #
      # Allowed locations:
      #  * :cursor - the location of the text cursor in the focussed text widget
      #  * :pointer - the location of the mouse pointer
      #
      # If :cursor is specified with no open tab, it will default to :pointer.
      #
      # @param [String] message
      # @param [Symbol] location
      def self.tool_tip(message, location)
        Redcar.gui.dialog_adapter.tool_tip(message, location)
      end
      
      # Shows a popup menu to the user.
      #
      # Allowed locations:
      #  * :cursor - the location of the text cursor in the focussed text widget
      #  * :pointer - the location of the mouse pointer
      #
      # If :cursor is specified with no open tab, it will default to :pointer.
      #
      # @param [Redcar::Menu] menu
      # @param [Symbol] location
      def self.popup_menu(menu, location)
        Redcar.gui.dialog_adapter.popup_menu(menu, location)
      end
    end
  end
end