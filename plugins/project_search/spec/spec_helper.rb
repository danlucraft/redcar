$:.push File.expand_path(File.dirname(__FILE__) + '../../../lib')

require 'redcar'
Redcar.environment = :test
Redcar.load_unthreaded

class ImmediateTaskQueue
  class Future
    def initialize(value)
      @value = value
    end
    
    def get
      @value
    end
  end
  
  def submit(task)
    Future.new(task.execute)
  end
end

Redcar::Resource.compute_synchronously = true

def project_search_fixture_dir
  File.dirname(__FILE__) + "/fixtures/project"
end