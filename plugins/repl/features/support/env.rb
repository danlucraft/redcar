
require File.join File.dirname(__FILE__), 'fake_repl'

Redcar::REPL::ReplMirror.class_eval do
  def evaluator
    @eval ||= Redcar::REPL::FakeEvaluator.new
  end

  def grammar_name
    "Plain Text"
  end

  def format_error(e)
    "An error was thrown: #{e}"
  end
end

Before do
  Redcar::REPL.storage['command_history'] = {}
end

def current_tab
  Redcar.app.focussed_window.focussed_notebook_tab
end