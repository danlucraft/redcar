module Redcar
  class AutoPairer
    class DocumentController
      include Redcar::Document::Controller
      include Redcar::Document::Controller::ModificationCallbacks
      include Redcar::Document::Controller::CursorCallbacks
      
      MarkPair ||= Struct.new(:start_mark, :end_mark, :text, :endtext)
      
      class MarkPair
        def inspect
          "<MarkPair start:#{start_mark.inspect} end:#{end_mark.inspect}>"
        end
      end
      
      def initialize
        @mark_pairs = []
      end
      
      def ignore
        @ignore ||= 0 
        @ignore += 1
        yield
        @ignore -= 1
        @ignore = nil if @ignore == 0
      end
      
      def ignore?
        @ignore
      end
      
      def add_mark_pair(pair)
        @mark_pairs << pair
        if @mark_pairs.length > 10
          p :Whoah_many_pairs
        end
      end
  
      # Forget about pairs if the cursor moves from within them
      def invalidate_pairs(offset)
        @mark_pairs.reject! do |mp|
          i1 = mp.start_mark.get_offset
          i2 = mp.end_mark.get_offset
          if offset < i1 or offset > i2
            document.delete_mark(mp.start_mark)
            document.delete_mark(mp.end_mark)
            true
          end
        end
      end
  
      def find_mark_pair_by_start(offset)
        @mark_pairs.find do |mp|
          mp.start_mark.get_offset == offset
        end
      end
  
      def find_mark_pair_by_end(offset)
        @mark_pairs.find do |mp|
          mp.end_mark.get_offset == offset
        end
      end

      def before_modify(start_offset, end_offset, text)
        return if ignore?
        @start_offset  = start_offset
        @end_offset    = end_offset
        @text          = text
        @selected_text = nil unless @ignore_insert
        if cursor_scope = document.cursor_scope
          # Type over ends
          if @rules = PairsForScope.pairs_for_scope(cursor_scope)
            inverse_rules = @rules.invert
            if inverse_rules.include?(text) and !@ignore_insert
              end_mark_pair = find_mark_pair_by_end(start_offset)
              if end_mark_pair and end_mark_pair.text == text
                @type_over_end = true
                #@buffer.parser.stop_parsing
              end
            end
            # Insert matching ends
            if !@type_over_end and @rules.include?(text) and !@ignore_insert and !@done
              @insert_end = true
              if document.selection?
                @selected_text = document.selected_text
              end
#              @buffer.parser.stop_parsing
            end
          end
        end
      end
      
      def after_modify
        return if ignore?
        @done = nil
        document.controllers(AutoIndenter::DocumentController).first.disable do
          # Deleted start of a mark pair
          if @end_offset == @start_offset + 1 and !@ignore_delete
            mark_pair = find_mark_pair_by_start(@start_offset)
            if mark_pair
              @ignore_delete = true
              document.delete(mark_pair.end_mark.get_offset, 1)
              @ignore_delete = false
              @mark_pairs.delete(mark_pair)
              @deletion = nil
            end
          end
          
          # Type over ends
          if @type_over_end
            @type_over_end = false
            @ignore_delete = true
            document.delete(@end_offset, 1)
            @ignore_delete = nil
            document.cursor_offset += 1
            #@buffer.parser.start_parsing
            @done = true
          end
          
          # Insert matching ends
          if @insert_end and !@ignore_insert
            @ignore_insert = true
            endtext = @rules[@text]
            document.insert(@start_offset + 1, endtext)
            mark1 = document.create_mark(@start_offset - 1,     :right)
            mark2 = document.create_mark(@start_offset, :right)
            add_mark_pair(MarkPair.new(mark1, mark2, @text, endtext))
            @ignore_insert = false
            #@buffer.parser.start_parsing
            @insert_end = false
          end
          
          if @selected_text and !@ignore_insert
            @ignore_insert = true
            offset = document.cursor_offset
            document.insert(@start_offset, @selected_text)
            document.cursor_offset = offset + @selected_text.length + 1
            @ignore_insert = false
            @selected_text = nil
          end
        end
        false
      end
      
      def cursor_moved(offset)
        return if ignore?
        if !@ignore_mark 
          invalidate_pairs(offset)
        end
      end
    end
  end
end
