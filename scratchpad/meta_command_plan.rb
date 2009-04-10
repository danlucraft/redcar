
class MyCommand < Redcar::Command
  def execute
    p :foo
  end
end

c = MyCommand.new
c.do

module CommandCharacter
  def executable?
  end
  
  def in_range?
  end
end

module CommandExecutor
  def do
  end
end

class Command
  extend CommandCharacter
  include CommandExecutor
end

class SnippetMetaCommand
  include CommandCharacter
  
  class Instance
    include CommandExecutor
    attr_accessor :command
    
    def execute
      tab.view.snippet_inserter.insert_snippet(command)
    end
  end
  
  def new
    c = Instance.new
    c.command = self
    c
  end
end

snippet_command = SnippetMetaCommand.new
snippet_command.tab_trigger = "def"
snippet_command.content = "def foo\n  \nend"
c = snippet_command.new
c.do

class ShellMetaCommand
  include CommandCharacter
  
  class Instance
    include CommandExecutor
    attr_accessor :command
    
    def execute
    end
  end
  
  def new
    c = Instance.new
    c.command = self
    c
  end
end

shell_command = ShellMetaCommand.new
shell_command.input = "def"
shell_command.script = "def foo\n  \nend"
c = shell_command.new
c.do

