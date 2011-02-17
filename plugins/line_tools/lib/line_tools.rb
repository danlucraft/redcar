
module Redcar
  class LineTools

    def self.menus
      Menu::Builder.build do
        sub_menu "Edit" do
          sub_menu "Line Tools" do
            item "Raise Region", LineTools::RaiseTextCommand
            item "Lower Region", LineTools::LowerTextCommand
            item "Replace Line", LineTools::ReplaceLineCommand
            item "Clear Line"  , LineTools::ClearLineCommand
            item "Trim Line"   , LineTools::TrimLineAfterCursorCommand
            item "Kill Line"   , LineTools::KillLineCommand
          end
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Alt+Up"      , RaiseTextCommand
        link "Alt+Down"    , LowerTextCommand
        link "Alt+Shift+R" , ReplaceLineCommand
        link "Alt+Shift+C" , ClearLineCommand
        link "Ctrl+Shift+K", KillLineCommand
        link "Ctrl+K"      , TrimLineAfterCursorCommand
      end
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Alt+Up"      , RaiseTextCommand
        link "Alt+Down"    , LowerTextCommand
        link "Alt+Shift+R" , ReplaceLineCommand
        link "Alt+Shift+C" , ClearLineCommand
        link "Ctrl+K"      , TrimLineAfterCursorCommand
        link "Ctrl+Shift+K", KillLineCommand
      end
      [osx, linwin]
    end

    class ReplaceLineCommand < Redcar::DocumentCommand
      sensitize :clipboard_not_empty
      def execute
        doc = tab.edit_view.document
        if doc.selection?
          first_line_ix = doc.line_at_offset(doc.selection_range.begin)
          last_line_ix  = doc.line_at_offset(doc.selection_range.end)
          text = doc.get_slice(doc.offset_at_line(first_line_ix),
                               doc.offset_at_line_end(last_line_ix))
        else
          first_line_ix = doc.cursor_line
          text = doc.get_line(first_line_ix)
        end
        doc.controllers(Redcar::AutoIndenter::DocumentController).first.disable do
          doc.replace(doc.offset_at_line(first_line_ix), text.split(//).length, "")
          Redcar::Top::PasteCommand.new.run
        end
      end
    end

    class ClearLineCommand < Redcar::DocumentCommand
      def execute
        doc = tab.edit_view.document
        if doc.selection?
          line_ix = doc.line_at_offset(doc.selection_range.begin)
          last_line_ix  = doc.line_at_offset(doc.selection_range.end)
          text = doc.get_slice(doc.offset_at_line(line_ix),
                               doc.offset_at_line_end(last_line_ix))
          lines = (last_line_ix - line_ix) + 1
        else
          line_ix = doc.cursor_line
          text = doc.get_line(line_ix)
          lines = 1
        end
        doc.controllers(Redcar::AutoIndenter::DocumentController).first.disable do
          doc.replace(doc.offset_at_line(line_ix), text.split(//).length, "\n" * lines)
        end
        doc.cursor_offset = doc.cursor_offset - 1
      end
    end

    class TrimLineAfterCursorCommand < Redcar::DocumentCommand
      def execute
        doc = tab.edit_view.document
        if doc.selection?
          offset = doc.selection_range.begin
          line_ix = doc.line_at_offset(offset)
          last_line_ix  = doc.line_at_offset(doc.selection_range.end)
          text = doc.get_slice(offset,doc.offset_at_line_end(last_line_ix))
        else
          offset = doc.cursor_offset
          line_ix = doc.line_at_offset(offset)
          text = doc.get_slice(offset, doc.offset_at_line_end(line_ix))
        end
        doc.controllers(Redcar::AutoIndenter::DocumentController).first.disable do
          if text == doc.line_delimiter or text == ""
            doc.replace(offset, text.split(//).length, "")
          else
            doc.replace(offset, text.split(//).length, doc.line_delimiter)
          end
        end
        #doc.cursor_offset = doc.cursor_offset - 1
      end
    end

    class KillLineCommand < Redcar::DocumentCommand
      def execute
        doc = tab.edit_view.document
        if doc.selection?
          line_ix = doc.line_at_offset(doc.selection_range.begin)
          last_line_ix  = doc.line_at_offset(doc.selection_range.end)
          text = doc.get_slice(doc.offset_at_line(line_ix),
                               doc.offset_at_line_end(last_line_ix))
        else
          line_ix = doc.cursor_line
          text = doc.get_line(line_ix)
        end
        doc.controllers(Redcar::AutoIndenter::DocumentController).first.disable do
          doc.replace(doc.offset_at_line(line_ix), text.split(//).length, "")
        end
      end
    end

    class RaiseTextCommand < Redcar::DocumentCommand
      def execute
        doc = tab.edit_view.document
        cursor_line_offset = doc.cursor_line_offset
        if doc.selection?
          first_line_ix = doc.line_at_offset(doc.selection_range.begin)
          last_line_ix  = doc.line_at_offset(doc.selection_range.end)

          if doc.selection_range.begin == doc.offset_at_inner_end_of_line(first_line_ix)
            first_line_ix += 1
          end
          if doc.selection_range.end == doc.offset_at_line(last_line_ix)
            last_line_ix -= 1
          end

          text = doc.get_slice(doc.offset_at_line(first_line_ix),
                               doc.offset_at_line_end(last_line_ix))
          keep_selection = true
        else
          first_line_ix = doc.cursor_line
          last_line_ix = first_line_ix
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
          doc.controllers(Redcar::AutoIndenter::DocumentController).first.disable do
            doc.compound do
              prev_line = doc.get_line(first_line_ix-1)
              swap_text = "#{prev_line}#{text}"
              new_text  = "#{text}#{prev_line}"
              unless /\n$/.match(text)
                new_text = "#{text}\n#{prev_line}"
              end
              doc.replace(doc.offset_at_line(first_line_ix-1), swap_text.split(//).length, new_text)
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
    end

    class LowerTextCommand < Redcar::DocumentCommand
      def execute
        doc = tab.edit_view.document
        cursor_line_offset = doc.cursor_line_offset
        if doc.selection?
          first_line_ix = doc.line_at_offset(doc.selection_range.begin)
          last_line_ix  = doc.line_at_offset(doc.selection_range.end)
          
          if doc.selection_range.begin == doc.offset_at_inner_end_of_line(first_line_ix)
            first_line_ix += 1
          end
          if doc.selection_range.end == doc.offset_at_line(last_line_ix)
            last_line_ix -= 1
          end
          
          text = doc.get_slice(doc.offset_at_line(first_line_ix),
                               doc.offset_at_line_end(last_line_ix))
          keep_selection = true
        else
          first_line_ix = doc.cursor_line
          last_line_ix = first_line_ix
          text = doc.get_line(doc.cursor_line)
        end
        #if last_line_ix == (doc.line_count - 1)
        #  text = "\n#{text}"
        #end
        if last_line_ix < doc.line_count - 1
          next_line = doc.get_line(last_line_ix+1)
          swap_text = "#{text}#{next_line}"
          if last_line_ix == doc.line_count - 2
            new_text  = "#{next_line}\n#{text}"
          else
            new_text  = "#{next_line}#{text}"
          end
          doc.controllers(Redcar::AutoIndenter::DocumentController).first.disable do
            doc.compound do
              doc.replace(doc.offset_at_line(first_line_ix), swap_text.split(//).length, new_text)
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
end
