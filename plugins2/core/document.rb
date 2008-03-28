
module Redcar
  Document = Gtk::SourceBuffer
  class Document
    extend FreeBASE::StandardPlugin
    
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

    def forward_word
      place_cursor(cursor_iter.forward_word_end!)
    end
    
    def backward_word
      place_cursor(cursor_iter.backward_word_start!)
    end
    
    def cursor=(obj)
      place_cursor(iter(obj))
    end
    
    def line_start(num)
      return iter(end_mark) if num == line_count
      get_iter_at_line(num)
    end
    
    def line_end(num)
      if num >= line_count - 1
        iter(end_mark)
      else
        line_start(num+1)
      end
    end
    
    def line_end1(num)
      if num >= line_count - 1
        iter(end_mark)
      else
        iter(line_start(num+1).offset-1)
      end
    end
    
    def get_line(num=nil)
      if num == nil
        return get_line(cursor_line)
      end
      if num == line_count-1
        end_iter = iter(end_mark)
      elsif num > line_count-1
        return nil
      elsif num < 0
        if num >= -line_count
          return get_line(line_count+num).chars
        else
          return nil
        end
      else
        end_iter = line_start(num+1)
      end
      get_slice(line_start(num), end_iter).chars
    end
    
    def start_mark
      get_mark("start-mark") or
        create_mark("start-mark", iter(0), true)
    end
    
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
    
    def cursor_line_offset
      iter(cursor_mark).line_offset
    end
  end
end
