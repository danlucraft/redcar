
require 'pair_highlighter/document_controller'

module Redcar
  class PairHighlighter

    def self.edit_view_gui_update(mate_text)
      if @styledText != mate_text.get_text_widget
        @styledText = mate_text.get_text_widget
        @styledText.add_key_listener(KeyListener.new)
        @styledText.addLineBackgroundListener(LineEventListener.new)
	      @doc.mate_text = mate_text
        @doc.styledText = @styledText
        @doc.gc = Swt::Graphics::GC.new(@styledText)
      end
    end
    
    def self.document_cursor_listener
      @doc = DocumentController.new
    end
    
    def self.theme_changed_update
      @doc.set_highlight_colour
    end
    
    class KeyListener
      def key_pressed(_); end
      def key_released(_); end
    end  
    
    class LineEventListener
      def lineGetBackground(_); end
    end
  end 
end
