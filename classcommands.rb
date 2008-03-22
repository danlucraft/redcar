
class TabCommand < Command
  sensitive :tab
end

class TextTabCommand < TabCommand
  sensitive :texttab
end

class FindNext < TextTabCommand
  key "Ctrl+G"
  menu "Edit/Find Next"
  
  def execute(tab)
    @re ||= FindNextDialog.new.run
    tab.find_next(re)
  end
end

class FindReplace < TextTabCommand
  key "Global/Ctrl+F"
  menu "Edit/Find and Replace"
  composite
  
  def execute(tab)
    d = FindReplaceDialog.new
    d.on_button do
      ReplaceText.new(d.find, d.replace).execute(tab)
    end
  end
end

class ReplaceText < TextTabCommand
  def initialize(find, replace)
    @find    = find
    @replace = replace
  end
  
  def execute(tab)
    tab.doc.replace_text(@find, @replace)
  end
end

class GotoLine < TextTabCommand
  key "Global/Ctrl+L"
  menu "Navigation/Goto Line"
  
  class GetlineSpeedbar < Speedbar
    label "Line:"
    textbox :line_text
    button "Go", "Return"
  end
  
  def execute(tab)
    unless @line
      sp = GetlineSpeedbar.new
      sp.on_button "Go" do
        sp.close
      end
      @line = sp.show
    end
    tab.doc.cursor_to_line_start @line
    tab.view.scroll_cursor_onscreen
  end
end
