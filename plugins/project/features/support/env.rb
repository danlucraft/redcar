
module DrbShelloutHelper
  def self.drb_system_thread
    $drb_system_thread
  end

  def self.drb_system_thread= value
    $drb_system_thread = value
  end

  def self.kill_thread
    if !($drb_system_thread.nil?) and $drb_system_thread.status
      $drb_system_thread.kill
    end
  end
end

def fixtures_path
  File.expand_path(File.dirname(__FILE__) + "/../../spec/fixtures")
end

def original_fixtures_path
  File.expand_path(File.dirname(__FILE__) + "/../../spec/fixtures.orig")
end

def create_project_fixtures
  clear_project_fixtures
  p [:cp_r, original_fixtures_path, fixtures_path]
  FileUtils.cp_r(original_fixtures_path, fixtures_path)
end

def clear_project_fixtures
  FileUtils.rm_rf(fixtures_path)
end

def make_subproject_fixtures
  FileUtils.mkdir_p(fixtures_path + "/myproject/test1")
  FileUtils.mkdir_p(fixtures_path + "/myproject/test2")
  FileUtils.mkdir_p(fixtures_path + "/myproject/.redcar")
  File.open(fixtures_path + "/myproject/.redcar/test_config", "w") {|f| f.print "this is a config file" }
  File.open(fixtures_path + "/myproject/test1/a.txt", "w") {|f| f.print "this is a project file" }
  File.open(fixtures_path + "/myproject/test1/b.txt", "w") {|f| f.print "this is a project file" }
  File.open(fixtures_path + "/myproject/test1/c.txt", "w") {|f| f.print "this is a project file" }
end

def filter_storage
  Redcar::Project::FindFileDialog.storage
end

Before("@project-fixtures") do
  create_project_fixtures
  @original_file_size_limit = Redcar::Project::Manager.file_size_limit
end

After("@project-fixtures") do
  Redcar::Project::Manager.reveal_files = true
  clear_project_fixtures
  DrbShelloutHelper.kill_thread
  Redcar::Project::Manager.file_size_limit = @original_file_size_limit
end
