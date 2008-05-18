
module Redcar
  Document = Gtk::SourceBuffer
  class Document
    extend FreeBASE::StandardPlugin

    attr_writer :parser, :indenter, :autopairer, :snippet_inserter
    attr_accessor :ignore_marks

    # The length of the document in characters.
    def length
      char_count
    end

    def iter(obj)
      case obj
      when Integer
        obj = [0, obj].max
        obj = [length, obj].min
        get_iter_at_offset(obj)
      when Gtk::TextMark
        get_iter_at_mark(obj)
      when Gtk::TextIter
        obj
      when Redcar::EditView::TextLoc
        line_start = get_iter_at_line(obj.line)
        iter(line_start.offset+obj.offset)
      end
    end

    # Move the cursor forward a word.
    def forward_word
      place_cursor(cursor_iter.forward_word_end!)
    end

    # Move the cursor back a word.
    def backward_word
      place_cursor(cursor_iter.backward_word_start!)
    end

    # Set the cursor position. Obj may be anything
    # Document#iter accepts.
    def cursor=(obj)
      place_cursor(iter(obj))
    end

    # Return a TextIter for the start of line num.
    def line_start(num)
      return iter(end_mark) if num == line_count
      get_iter_at_line(num)
    end

    # Return a TextIter for the end of line num.
    # (Equal to line_start(num+1))
    def line_end(num)
      if num >= line_count - 1
        iter(end_mark)
      else
        line_start(num+1)
      end
    end

    # Return a TextIter for the end of line num,
    # before the "\n" line terminator.
    def line_end1(num)
      if num >= line_count - 1
        iter(end_mark)
      else
        iter(line_start(num+1).offset-1)
      end
    end

    # Get the text in line num. If num is nil,
    # the current line is returned.
    def get_line(num=nil)
      if num == nil
        return get_line(cursor_line)
      end
      if num == line_count-1
        end_iter = iter(end_mark)
      elsif num > line_count-1
        return nil
      elsif num < 0
        return nil
      else
        end_iter = line_start(num+1)
      end
      get_slice(line_start(num), end_iter).to_s
    end

    # Get a Gtk::TextMark for the start of the document.
    def start_mark
      get_mark("start-mark") or
        create_mark("start-mark", iter(0), true)
    end

    # Get a Gtk::TextMark for the end of the document.
    def end_mark
      get_mark("end-mark") or
        create_mark("end-mark", iter(char_count), false)
    end

    def cursor_mark
      get_mark("insert")
    end

    def cursor_iter
      iter(get_mark("insert"))
    end

    def cursor_line
      iter(cursor_mark).line
    end

    def cursor_offset
      iter(cursor_mark).offset
    end

    def cursor_scope
      if @parser
        @parser.scope_at(TextLoc(cursor_line, cursor_line_offset))
      end
    end

    def scope_at(line, line_offset)
      if @parser
        @parser.scope_at(TextLoc(line, line_offset))
      end
    end

    def cursor_line_offset
      iter(cursor_mark).line_offset
    end

    def selection_mark
      get_mark("selection_bound")
    end

    def selection_iter
      iter(selection_mark)
    end

    def selection_offset
      iter(selection_mark).offset
    end

    def selection?
      start_iter, end_iter, bool = selection_bounds
      bool
    end

    def selection_range
      start_iter, end_iter, bool = selection_bounds
      (start_iter.offset)..(end_iter.offset)
    end

    def selection_offset
      iter(selection_mark).offset
    end

    def selection
      get_text(selection_iter, cursor_iter)
    end

    def select(from, to)
      off1 = iter(from).offset
      off2 = iter(to).offset
      if off1 < off2
        minoff = off1
        maxoff = off2
      else
        minoff = off2
        maxoff = off1
      end
      move_mark(selection_mark, iter(minoff))
      move_mark(cursor_mark, iter(maxoff))
#      @textview.scroll_mark_onscreen(cursor_mark)
    end

    def delete_selection
      if selection?
        delete(cursor_iter, selection_iter)
      end
    end

    def replace_selection(text=nil)
      current_text = selection
      startiter, enditer, b = selection_bounds
      startsel = startiter.offset
      endsel   = enditer.offset
      delete_selection
      if text==nil
        if block_given?
          new_text = yield(current_text.chars)
        end
      else
        new_text = text
      end
      insert(cursor_iter, new_text)
      select(startsel, startsel+new_text.length)
    end

    def replace_line(text=nil)
      current_text = get_line
      current_cursor = cursor_offset
      startiter, enditer, b = selection_bounds
      startsel = startiter.offset
      endsel   = enditer.offset
      delete(line_start(cursor_line),
             line_end(cursor_line))
      if text==nil
        if block_given?
          new_text = yield(current_text.chars)
        end
      else
        new_text = text
      end
      insert(line_start(cursor_line), new_text)
      place_cursor(iter(current_cursor))
      select(startsel, endsel)
    end

    def indent_line(line_num)
      @indenter.indent_line(line_num) if @indenter
    end

    def type(text)
      text.split(//).each {|l| insert_at_cursor(l)}
    end
    
    class IgnoreObject
      def ignore
        yield
      end
    end
    
    def parser
      @parser || IgnoreObject.new
    end
    
    def indenter
      @indenter || IgnoreObject.new
    end

    def autopairer
      @autopairer || IgnoreObject.new
    end
    
    def snippet_inserter
      @snippet_inserter || IgnoreObject.new
    end
  end
end
