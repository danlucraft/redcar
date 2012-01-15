require 'pathname'

require 'sessions/memory'
require 'sessions/loader'
require 'sessions/cursor_saver'

class Sessions
  def self.project_loaded(project)
    Sessions::Memory.project_loaded(project)
    Sessions::Loader.project_loaded(project)
  end

  def self.project_closed(project, window)
    Sessions::Memory.project_closed(project, window)
    Sessions::Loader.project_closed(project, window)
    Sessions::CursorSaver.project_closed(project, window)
  end
  
  def self.tab_added(tab)
    Sessions::CursorSaver.tab_added(tab)
  end
end