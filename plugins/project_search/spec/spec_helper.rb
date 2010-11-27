$:.push File.expand_path(File.dirname(__FILE__) + '../../../lib')

require 'redcar'
Redcar.environment = :test
Redcar.load_unthreaded

def project_search_fixture_dir
  File.dirname(__FILE__) + "/fixtures/project"
end