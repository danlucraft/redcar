
Before do
  Redcar::REPL.storage['command_history'] = {}
end

def current_tab
  Redcar.app.focussed_window.focussed_notebook_tab
end