
##########################################
class FindNextPlugin < Redcar::Plugin
  menu "Edit", :icon => :PREFERENCES do
    item("Find Next", 
         :icon => :FORWARD, 
         :sensitive => :texttab?,
         :key => "Global/Ctrl+G",
         :record => false) do
      re = FindNextDialog.new
      tab.find_next re
    end
  end
end

class TextTab
  record
  def find_next(re)
    # do actual find_next work
  end
end

##########################################

class FindNextPlugin < Redcar::Plugin
  plugin_commands do
    key "Global/Ctrl+G"
    sensitive :texttab?
    norecord
    def self.find_next
      re = FindNextDialog.new
      tab.find_next re
    end
  end
  
  main_menu "Edit" do
    item "Find Next", :find_next, :FORWARD
  end
end

class TextTab
  tab_command
  def find_next(re)
    # do actual find_next work
  end
end

#################################
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

class GotoLine < TextTabCommand
  key "Ctrl+L"
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
