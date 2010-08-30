
module Redcar
  class LineTools

    def self.menus
      Menu::Builder.build do
        sub_menu "Edit" do
          group(:priority => 80) do
            sub_menu "Line Tools" do
              item "Raise Region", LineTools::RaiseTextCommand
              item "Lower Region", LineTools::LowerTextCommand
              item "Trim Line", LineTools::TrimLineAfterCursorCommand
              item "Kill Line", LineTools::KillLineCommand
              item "Replace Line", LineTools::ReplaceLineCommand
            end
          end
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Alt+Shift+Up", RaiseTextCommand
        link "Alt+Shift+Down", LowerTextCommand
      end
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Alt+Shift+Up", RaiseTextCommand
        link "Alt+Shift+Down", LowerTextCommand
      end
      [osx, linwin]
    end

    class ReplaceLineCommand < Redcar::DocumentCommand
      def execute
        #TODO: implement me!
      end
    end

    class ClearLineCommand < Redcar::DocumentCommand
      def execute
        #TODO: implement me!
      end
    end

    class TrimLineAfterCursorCommand < Redcar::DocumentCommand
      def execute
        #TODO: implement me!
      end
    end

    class KillLineCommand < Redcar::DocumentCommand
      def execute
        #TODO: implement me!
      end
    end

    class RaiseTextCommand < Redcar::DocumentCommand
      def execute
        doc = tab.edit_view.document
        cursor_line_offset = doc.cursor_line_offset
        if doc.selection?
          first_line_ix = doc.line_at_offset(doc.selection_range.begin)
          last_line_ix  = doc.line_at_offset(doc.selection_range.end)
          text = doc.get_slice(doc.offset_at_line(first_line_ix),
                               doc.offset_at_line_end(last_line_ix))
          keep_selection = true
        else
          first_line_ix = doc.cursor_line
          last_line_ix = doc.cursor_line
          text = doc.get_line(doc.cursor_line)
        end
        if first_line_ix > 0
          if first_line_ix == 1
            top = 0
            insert_idx = doc.offset_at_line(top)
          else
            top = first_line_ix - 2
            insert_idx = doc.offset_at_line_end(top)
          end
          doc.compound do
            doc.delete(doc.offset_at_line(first_line_ix), text.length)
            #if last_line_ix == doc.line_count - 1 or not
            unless /\n$/.match(text)
              text = "#{text}\n"
            end
            doc.insert(insert_idx, text)
            doc.cursor_offset = insert_idx + cursor_line_offset
            if keep_selection
              doc.set_selection_range(doc.offset_at_line(first_line_ix-1),
              doc.offset_at_line(last_line_ix-1) + doc.get_line(last_line_ix-1).length - 1)
            end
            doc.scroll_to_line(top)
          end
        end
      end
    end

    class LowerTextCommand < Redcar::DocumentCommand
      def execute
        doc = tab.edit_view.document
        cursor_line_offset = doc.cursor_line_offset
        if doc.selection?
          first_line_ix = doc.line_at_offset(doc.selection_range.begin)
          last_line_ix  = doc.line_at_offset(doc.selection_range.end)
          text = doc.get_slice(doc.offset_at_line(first_line_ix),
                               doc.offset_at_line_end(last_line_ix))
          keep_selection = true
        else
          first_line_ix = doc.cursor_line
          last_line_ix = doc.cursor_line
          text = doc.get_line(doc.cursor_line)
        end
        #if last_line_ix == (doc.line_count - 1)
        #  text = "\n#{text}"
        #end
        if last_line_ix < doc.line_count - 1
          prev_line = doc.get_line(last_line_ix+1)
          swap_text = "#{text}#{prev_line}"
          if last_line_ix == doc.line_count - 2
            new_text  = "#{prev_line}\n#{text}"
          else
            new_text  = "#{prev_line}#{text}"
          end
          doc.compound do
            doc.replace(doc.offset_at_line(first_line_ix), swap_text.length, new_text)
            doc.cursor_offset = doc.offset_at_line(last_line_ix+1) + cursor_line_offset
            if keep_selection
              doc.set_selection_range(doc.offset_at_line(first_line_ix+1),
              doc.offset_at_line(last_line_ix+1) + doc.get_line(last_line_ix+1).length - 1)
            end
            doc.scroll_to_line(last_line_ix+1)
          end
        end
      end
    end
  end
end