
Redcar.plugin_manager.load("core")

class QuickTask < Redcar::Task
  def initialize(id=nil)
    @id = id
  end
  
  def execute
    $started_tasks << @id
    :hiho
  end
  
  def inspect
    "<#{self.class} #{@id}>"
  end
end

class BlockingTask < QuickTask
  def execute
    $started_tasks << @id
    loop { break if java.lang.Thread.interrupted }
  end
end
