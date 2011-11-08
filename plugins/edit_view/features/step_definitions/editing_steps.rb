
def unescape_text(text)
  text.gsub("\\t", "\t").gsub("\\n", "\n").gsub("\\r", "\r").gsub("\\\"", "\"")
end

def escape_text(text)
  text.gsub("\t", "\\t").gsub("\n", "\\n").gsub("\r", "\\r").gsub("\"", "\\\"")
end

When /^I undo$/ do
  Swt.sync_exec do
    Redcar::Top::UndoCommand.new.run(:env => {:edit_view => implicit_edit_view})
  end
end

When /^I redo$/ do
  Swt.sync_exec do
    Redcar::Top::RedoCommand.new.run(:env => {:edit_view => implicit_edit_view})
  end
end

When /^I select (-?)(\d+) from \((\d+), ?(\d+)\)$/ do |minus, length, start_line, start_line_offset|
  length = length.to_i
  length = length * -1 if minus == "-"
  Swt.bot.styled_text.select_range(start_line.to_i, start_line_offset.to_i, length)
end

When /^I select from \((\d+), ?(\d+)\) to \((\d+), ?(\d+)\)$/ do |start_line, start_line_offset, end_line, end_line_offset|
  length = nil
  Swt.sync_exec do
    doc = implicit_edit_view.document
    start_of_end_line = doc.offset_at_line(end_line.to_i)
    end_offset = start_of_end_line + end_line_offset.to_i
    
    start_of_start_line = doc.offset_at_line(start_line.to_i)
    start_offset = start_of_start_line + start_line_offset.to_i
    length = end_offset - start_offset
  end
  Swt.bot.styled_text.select_range(start_line.to_i, start_line_offset.to_i, length)
end

When /^I select from (\d+) to (\d+)$/ do |start_offset, end_offset|
  Swt.sync_exec do
    doc = implicit_edit_view.document
    doc.set_selection_range(start_offset.to_i, end_offset.to_i)
  end
end

When /^I copy text$/ do
#  Redcar::Top::CopyCommand.new.run(:env => {:edit_view => implicit_edit_view})
  When "I select menu item \"Edit|Copy\""
end

When /^I cut text$/ do
  # Redcar::Top::CutCommand.new.run(:env => {:edit_view => implicit_edit_view})
  When "I select menu item \"Edit|Cut\""
end

When /^I paste text$/ do
  # Redcar::Top::PasteCommand.new.run(:env => {:edit_view => implicit_edit_view})
  When "I select menu item \"Edit|Paste\""
end

When /^I move the cursor to (\d+)$/ do |offset|
  Swt.sync_exec do
    implicit_edit_view.document.cursor_offset = offset.to_i
  end
end

When /^I move the cursor to \((\d+),(\d+)\)$/ do |line, line_offset|
  Swt.bot.styled_text.navigate_to(line.to_i, line_offset.to_i)
end

When /^I move the cursor to the end of the document$/ do
  Swt.sync_exec do
    doc = implicit_edit_view.document
    doc.cursor_offset = doc.length
  end
end

Then /^the cursor should be at \((\d+),(\d+)\)$/ do |line, line_offset|
  position = Swt.bot.styled_text.cursor_position
  position.line.should == line.to_i
  position.column.should == line_offset.to_i
end

Then /^the cursor should be at (\d+)$/ do |offset|
  Swt.sync_exec do
    doc = implicit_edit_view.document
    doc.cursor_offset.should == offset.to_i
  end
end

When /^tabs are hard$/ do
  Swt.sync_exec do
    implicit_edit_view.soft_tabs = false
  end
end

When /^tabs are soft, (\d+) spaces$/ do |int|
  Swt.sync_exec do
    implicit_edit_view.soft_tabs = true
    implicit_edit_view.tab_width = int.to_i
  end
end

When /^I insert "(.*)" at the cursor$/ do |text|
  Swt.sync_exec do
    implicit_edit_view.document.insert_at_cursor(unescape_text(text))
  end
end

When /^I insert "(.*)" at (\d+)$/ do |text, offset_s|
  Swt.sync_exec do
    implicit_edit_view.document.insert(offset_s.to_i, unescape_text(text))
  end
end

When /^I replace (\d+) to (\d+) with "(.*)"$/ do |from, to, text|
  Swt.sync_exec do
    implicit_edit_view.document.replace(from.to_i, to.to_i - from.to_i, unescape_text(text))
  end
end

When /^I press the Tab key in the edit tab$/ do
  Swt.sync_exec do
    implicit_edit_view.tab_pressed([])
  end
end

When /^I press Shift\+Tab in the edit tab$/ do
  Swt.sync_exec do
    implicit_edit_view.tab_pressed(["Shift"])
  end
end

When /^I press the Left key in the edit tab$/ do
  Swt.sync_exec do
    implicit_edit_view.left_pressed([])
  end
end

When /^I press the Right key in the edit tab$/ do
  Swt.sync_exec do
    implicit_edit_view.right_pressed([])
  end
end

When /^I press Shift\+Left key in the edit tab$/ do
  Swt.sync_exec do
    implicit_edit_view.left_pressed(["Shift"])
  end
end

When /^I press Shift\+Right key in the edit tab$/ do
  Swt.sync_exec do
    implicit_edit_view.right_pressed(["Shift"])
  end
end

When /^I press the Delete key in the edit tab$/ do
  Swt.sync_exec do
    implicit_edit_view.delete_pressed([])
  end
end

When /^I press the Backspace key in the edit tab$/ do
  Swt.bot.styled_text.type_text("\b")
end

Then /^the contents should (not )?be "(.*)"$/ do |negative,text|
  Swt.sync_exec do
    expected = unescape_text(text)
    doc = implicit_edit_view.document
    actual = doc.to_s
    if expected.include?("<c>")
      char_curoff = doc.cursor_offset
      actual = actual.insert(actual.char_offset_to_byte_offset(char_curoff), "<c>")
      char_seloff = doc.selection_offset
      if char_seloff > char_curoff
        char_seloff += 3
      end
      actual = actual.insert(actual.char_offset_to_byte_offset(char_seloff), "<s>") unless char_curoff == char_seloff
    end
    if negative
      actual.should_not == expected
    else
      actual.should == expected
    end
  end
end

Then /^the contents of the edit tab should be "(.*)"$/ do |text|
  Swt.sync_exec do
    implicit_edit_view.document.to_s.should == unescape_text(text)
  end
end

When /^I block select from (\d+) to (\d+)$/ do |from_str, to_str|
  Swt.sync_exec do
    doc = implicit_edit_view.document
    doc.block_selection_mode = true
    doc.set_selection_range(from_str.to_i, to_str.to_i)
  end
end

Then /^the selection range should be from (\d+) to (\d+)$/ do |from_str, to_str|
  Swt.sync_exec do
    doc = implicit_edit_view.document
    r = doc.selection_range
    r.begin.should == from_str.to_i
    r.end.should == to_str.to_i
  end
end

Then /^the selection should be on line (.*)$/ do |line_num|
  Swt.sync_exec do
    line_num = line_num.to_i
    doc = implicit_edit_view.document
    r = doc.selection_range
    doc.line_at_offset(r.begin).should == line_num
    doc.line_at_offset(r.end).should == line_num
  end
end

Then /^there should not be any text selected$/ do
  Swt.sync_exec do
    doc = implicit_edit_view.document
    doc.selected_text.should == ""
  end
end

Then /^the selected text should be "([^"]*)"$/ do |selected_text|
  Swt.bot.styled_text.selection.should == unescape_text(selected_text)
end

Then /the line delimiter should be "(.*)"/ do |delim|
  Swt.sync_exec do
    doc = implicit_edit_view.document
    doc.delim.should == unescape_text(delim)
  end
end

When /^I move to line (\d+)$/ do |num|
  Swt.sync_exec do
    doc = implicit_edit_view.document
    doc.cursor_offset = doc.offset_at_line(num.to_i)
  end
end

Then /^the cursor should be on line (\d+)$/ do |num|
  Swt.sync_exec do
    doc = implicit_edit_view.document
    doc.cursor_line.should == num.to_i
  end
end

When /^I replace the contents with "((?:[^\"]|\\")*)"$/ do |contents|
  Swt.sync_exec do
    contents = unescape_text(contents)
    doc = implicit_edit_view.document
    cursor_offset = (contents =~ /<c>/)
    doc.text = contents.gsub("<c>", "")
    doc.cursor_offset = cursor_offset if cursor_offset
  end
end

When /^I replace the contents with 100 lines of "([^"]*)" then "([^"]*)"$/ do |contents1, contents2|
  Swt.sync_exec do
    contents1 = unescape_text(contents1)
    contents2 = unescape_text(contents2)
    doc = implicit_edit_view.document
    doc.text = (contents1 + "\n")*100 + contents2
  end
end

When /^I replace the contents with (\d+) "([^"]*)" then "([^"]*)"$/ do |count, contents1, contents2|
  Swt.sync_exec do
    contents1 = unescape_text(contents1)
    contents2 = unescape_text(contents2)
    doc = implicit_edit_view.document
    doc.text = (contents1)*count.to_i + contents2
  end
end

When /^I scroll to the top of the document$/ do
  Swt.sync_exec do
    doc = implicit_edit_view.document
    doc.scroll_to_line(0)
  end
end

Then /^line number (\d+) should be visible$/ do |line_num|
  Swt.sync_exec do
    line_num = line_num.to_i
    doc = implicit_edit_view.document
    (doc.biggest_visible_line >= line_num).should be_true
    (doc.smallest_visible_line <= line_num).should be_true
  end
end

Then /^horizontal offset (\d+) should be visible$/ do |offset|
  Swt.sync_exec do
    offset = offset.to_i
    doc    = implicit_edit_view.document
    (doc.largest_visible_horizontal_index  >= offset).should be_true
    (doc.smallest_visible_horizontal_index <= offset).should be_true
  end
end

When /^I select the word (right of|left of|around|at) (\d+)$/ do |direction, offset|
  Swt.sync_exec do
    offset = offset.to_i
    doc = implicit_edit_view.document
    case direction
    when "right of"
      range = doc.match_word_right_of(offset)
    when "left of"
      range = doc.match_word_left_of(offset)
    when "around"
      range = doc.match_word_around(offset)
    when "at"
      range = doc.word_range_at_offset(offset)
    else
      warn "unrecognized direction"
      range = offset..offset
    end
    doc.set_selection_range(range.first, range.last)
  end
end

When /^I turn block selection on$/ do
  Swt.sync_exec do
    implicit_edit_view.document.block_selection_mode?.should == false
    Redcar::Top::ToggleBlockSelectionCommand.new.run(:env => {:edit_view => implicit_edit_view})
  end
end

When /^I turn block selection off$/ do
  Swt.sync_exec do
    implicit_edit_view.document.block_selection_mode?.should == true
    Redcar::Top::ToggleBlockSelectionCommand.new.run(:env => {:edit_view => implicit_edit_view})
  end
end

def escape_text(text)
  text.gsub("\t", "\\t").gsub("\n", "\\n").gsub("\r", "\\r").gsub("\"", "\\\"")
end

Given /^the contents? is:$/ do |string|
  Swt.sync_exec do
    cursor_index    = string.index('<c>')
    selection_index = string.index('<s>')
    string = string.gsub('<s>', '').gsub('<c>', '')
    When %{I replace the contents with "#{string}"}
  
    if cursor_index and selection_index
      if cursor_index < selection_index
        selection_index -= 3
      else
        cursor_index -= 3
      end
      When %{I select #{cursor_index - selection_index} from #{selection_index}}
    elsif cursor_index
      When "I move the cursor to #{cursor_index}"
    end
  end
end

Then /^the content? should be:$/ do |string|
  Then %{the contents should be "#{escape_text(string)}"}
end

def implicit_edit_tab
  wn = Redcar.app.focussed_window
  nb = wn.focussed_notebook
  tab = nb.focussed_tab
  if tab.is_a?(Redcar::EditTab)
    tab
  else
    nil
  end
end

def implicit_edit_view
  edit_views = Redcar::EditView.all_edit_views
  focussed_edit_view = Redcar::EditView.focussed_edit_view
  ev =  if edit_views.length == 1
          edit_views.first
        elsif focussed_edit_view
          focussed_edit_view
        else
          if edit_tab = implicit_edit_tab
            edit_tab.edit_view
          end
        end
  raise "no implicit edit view (#{edit_views.length} open)" unless ev
  ev
end

When /^I type "((?:[^"]|\\")*)"$/ do |text|
  text = text.gsub("\\t", "\t").gsub("\\n", "\n").gsub("\\\"", "\"")
  Swt.bot.styled_text.type_text(text)
end

edit_view_action_steps = {
  :LINE_UP                => "I move up",
  :LINE_DOWN              => "I move down",
  :LINE_START             => "I move to the start of the line",
  :LINE_END               => "I move to the end of the line",
  :COLUMN_PREVIOUS        => "I move left",
  :COLUMN_NEXT            => "I move right",
  :PAGE_UP                => "I page up",
  :PAGE_DOWN              => "I page down",
  :WORD_PREVIOUS          => "I move to the previous word",
  :WORD_NEXT              => "I move to the next word",
  :TEXT_START             => "I move to the start of the text",
  :TEXT_END               => "I move to the end of the text",
  :WINDOW_START           => "I move to the start of the window",
  :WINDOW_END             => "I move to the end of the window",
  # :SELECT_ALL             => "I select all",
  :SELECT_LINE_UP         => "I select up",
  :SELECT_LINE_DOWN       => "I select down",
  :SELECT_LINE_START      => "I select to the start of the line",
  :SELECT_LINE_END        => "I select to the end of the line",
  :SELECT_COLUMN_PREVIOUS => "I select left",
  :SELECT_COLUMN_NEXT     => "I select right",
  :SELECT_PAGE_UP         => "I select page up",
  :SELECT_PAGE_DOWN       => "I select page down",
  :SELECT_WORD_PREVIOUS   => "I select to the previous word",
  :SELECT_WORD_NEXT       => "I select to the next word",
  :SELECT_TEXT_START      => "I select to the start of the text",
  :SELECT_TEXT_END        => "I select to the end of the text",
  :SELECT_WINDOW_START    => "I select to the start of the window",
  :SELECT_WINDOW_END      => "I select to the end of the window",
  :CUT                    => "dsafjl;fjsadfk",
  :COPY                   => "asdfkjalsgj",
  :PASTE                  => "asdfasdfe",
  :DELETE_PREVIOUS        => "I backspace",
  :DELETE_NEXT            => "I delete",
  :DELETE_WORD_PREVIOUS   => "I delete to the previous word",
  :DELETE_WORD_NEXT       => "I delete to the next word"
}

When "I select all" do
  char_count = Redcar.update_gui do
    Swt.bot.styled_text.widget.get_char_count
  end
  Swt.bot.styled_text.select_range(0, 0, char_count)
end

edit_view_action_steps.each do |action_symbol, step_text|
  When step_text do
    Swt.sync_exec do
      implicit_edit_view.invoke_action(action_symbol)
    end
  end
end


