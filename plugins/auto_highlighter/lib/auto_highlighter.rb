require 'auto_highlighter/document_controller'
module Redcar
  class AutoHighlighter

    def self.styledText_update(styledText)
      if @styledText != styledText
        styledText.add_key_listener(KeyListener.new)
        styledText.addLineBackgroundListener(LineEventListener.new)
        @styledText = styledText
        @doc.styledText = @styledText
        @doc.gc = Swt::Graphics::GC.new(styledText)
      end
    end

    def self.document_cursor_listener
      @doc = DocumentController.new
    end
    
    def	self.key_listener()
      @key_listener = KeyListener.new()
    end

    def	self.line_listener()
      @line_listener = LineEventListener.new()
    end
    
    class KeyListener
        def key_pressed(_)
          
        end
        def key_released(_)
        end
    end
    
    class LineEventListener
      def lineGetBackground(event)
        
      end
    end
  end 
end