require File.join(Redcar.asset_dir, "svnkit")
require 'java'
import 'org.tmatesoft.svn.core.io.SVNRepositoryFactory'

def scm_svn_fixtures
  File.expand_path(File.dirname(__FILE__) + "/../fixtures")
end

# minus 3 for '.' and '..' and '.svn'
def repo_file_count(path)
  (Dir.entries(path).size - 3).to_i
end

def parse_branch_path(branch_name)
  if branch_name == 'trunk'
    svn_module.trunk_path
  else
    svn_module.branch_path + "/#{branch_name}"
  end
end

def svn_repository
  "#{scm_svn_fixtures}/test_repo"
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
  FileUtils.mkdir_p "#{scm_svn_fixtures}/#{path}"
  File.expand_path("#{scm_svn_fixtures}/#{path}")
end

def get_dir(path)
  File.expand_path("#{scm_svn_fixtures}/#{path}")
end

def svn_module
  @svn_module ||= Redcar::Scm::Subversion::Manager.new
end

def svn_module_2
  @svn_module_2 ||= Redcar::Scm::Subversion::Manager.new
end

def reset_fixtures
  FileUtils.rm_rf scm_svn_fixtures
  FileUtils.mkdir_p scm_svn_fixtures
  FileUtils.mkdir_p File.dirname(svn_repository)
  SVNRepositoryFactory.createLocalRepository(Java::JavaIo::File.new(svn_repository),true,false)
  svn_module
end

Before do
  @svn_module = nil
  reset_fixtures
end

After do
  FileUtils.rm_rf(scm_svn_fixtures)
  @svn_module = nil
end
