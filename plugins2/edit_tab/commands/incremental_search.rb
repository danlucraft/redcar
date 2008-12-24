
module Redcar
  class AskIncrementalSearch < Redcar::EditTabCommand
    key "Ctrl+S"
    norecord
    
    class Speedbar < Redcar::Speedbar
      label "Search"
      
      textbox :query do |tab, text|
        if @start_offset
          tab.document.cursor = @start_offset
        else
          @start_offset = tab.document.cursor_iter.offset
        end
        
        FindForward.new(text).do(:replace_previous => true)
      end

      button "Prev", nil, "Super+Shift+S" do |sb|
        sb.tab.document.cursor = [sb.tab.document.cursor_offset, sb.tab.document.selection_offset].min
        FindBack.new(sb.query).do
      end
      
      button "Next", nil, "Super+S" do |sb|
        FindForward.new(sb.query).do
      end
      
      key("Up") { |sb| sb.close }
      key("Down") { |sb| sb.close }
     end
    
    class FindForward < Redcar::EditTabCommand
      def initialize(text)
        @text = text
      end
      
      def execute
        start_iter = doc.cursor_iter
        match_start, match_end = start_iter.forward_search(@text, Gtk::TextIter::SOURCE_SEARCH_CASE_INSENSITIVE, nil)
        if match_start
          doc.select(match_start, match_end)
          view.scroll_to_mark(doc.cursor_mark, 0.0, true, 0.5, 0.5)
        end
      end
    end
    
    class FindBack < Redcar::EditTabCommand
      def initialize(text)
        @text = text
      end
      
      def execute
        start_iter = doc.cursor_iter
        match_start, match_end = start_iter.backward_search(@text, Gtk::TextIter::SOURCE_SEARCH_CASE_INSENSITIVE, nil)
        if match_start
          doc.select(match_start, match_end)
          view.scroll_to_mark(doc.cursor_mark, 0.0, true, 0.5, 0.5)
        end
      end
    end
    
    def execute
      sp = Speedbar.new
      sp.show(tab)
    end
  end
end  
