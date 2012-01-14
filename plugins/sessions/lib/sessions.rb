require 'sessions/memory'

class Sessions
  def self.memories
    @memories ||= []
  end

  def self.project_loaded(project)
    memories << Sessions::Memory.new(project).recall
  end

  def self.project_closed(project, window)
    memories.reject! do |mem|
      mem.save window if mem.project == project
    end
  end
end