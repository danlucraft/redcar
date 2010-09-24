RequireSupportFiles File.dirname(__FILE__) + "/../../../project/features/"
require File.join(File.dirname(__FILE__), %w{.. .. vendor svnkit})
require 'java'
import 'org.tmatesoft.svn.core.io.SVNRepositoryFactory'

def fixtures
  File.expand_path(File.dirname(__FILE__) + "/../fixtures")
end

# minus 3 for '.' and '..' and '.svn'
def repo_file_count(path)
  (Dir.entries(path).size - 3).to_i
end

def svn_repository
  "#{fixtures}/test_repo"
end

def working_copy
  "my_repo"
end

def working_copy_2
  "my_repo_2"
end

def svn_repository_url
  "file://" + File.expand_path(svn_repository)
end

def create_dir(path)
  FileUtils.mkdir_p "#{fixtures}/#{path}"
  File.expand_path("#{fixtures}/#{path}")
end

def get_dir(path)
  File.expand_path("#{fixtures}/#{path}")
end

def svn_module
  @svn_module ||= Redcar::Scm::Subversion::Manager.new
end

def svn_module_2
  @svn_module_2 ||= Redcar::Scm::Subversion::Manager.new
end

def reset_fixtures
  FileUtils.rm_rf fixtures
  FileUtils.mkdir_p fixtures
  FileUtils.mkdir_p File.dirname(svn_repository)
  SVNRepositoryFactory.createLocalRepository(Java::JavaIo::File.new(svn_repository),true,false)
  svn_module
end

Before do
  @svn_module = nil
  reset_fixtures
end

After do
  FileUtils.rm_rf fixtures
  @svn_module = nil
end