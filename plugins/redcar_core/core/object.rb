
# Some useful methods for finding the currently focussed objects.
class Object
  # The current or last focussed Document.
  def doc
    tab.document
  end
  
  # The current or last focussed Tab
  def tab
    win.focussed_tab
  end
  
  # The current or last focussed Window
  def win
    Redcar::App.focussed_window
  end
end
