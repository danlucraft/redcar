module Redcar
  class ApplicationSWT
  
    # The controller for a Clipboard. In SWT a clipboard can only contain
    # one piece of text, but that's ok because inside Redcar all the Paste 
    # commands are implemented directly from the model. This is only useful
    # for copying/pasting between other applications and Redcar.
    class Clipboard
      def initialize(model)
        @model = model
        @model.controller = self
        @swt_clipboard = Swt::DND::Clipboard.new(Redcar.app.controller.display)
        attach_model_listeners
      end
      
      def plain_text_data_type
        Swt::DND::TextTransfer.get_instance
      end
      
      def attach_model_listeners
        @model.add_listener(:added) do |text|
          @swt_clipboard.set_contents(text, plain_text_data_type)
        end
      end
    end
  end
end
