
module Redcar
  class LineTools

    def self.menus
      Menu::Builder.build do
        sub_menu "Edit" do
          item "Raise Region", :command => LineTools::RaiseTextCommand, :priority => 22
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "F5", RaiseTextCommand
      end
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "F5", RaiseTextCommand
      end
      [osx, linwin]
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
        if last_line_ix == (doc.line_count - 1)
          text = "\n#{text}"
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
            #delete current selection
            doc.delete(doc.offset_at_line(first_line_ix), text.length)
            #insert text above previous line
            doc.insert(insert_idx, text)
            #set cursor to same line offset in new section
            doc.cursor_offset = insert_idx + cursor_line_offset
            if keep_selection
              #select duplicated region of text
              doc.set_selection_range(doc.cursor_offset, doc.cursor_offset + (text.length - 1))
            end
            doc.scroll_to_line(top)
          end
        end
      end
    end
  end
end