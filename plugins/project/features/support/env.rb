
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

require File.dirname(__FILE__) + "/../../spec/fixture_helper"

def filter_storage
  Redcar::Project::FindFileDialog.storage
end

Before("@project-fixtures") do
  ProjectFixtureHelper.create_project_fixtures
  ProjectFixtureHelper.make_subproject_fixtures
  @original_file_size_limit = Redcar::Project::Manager.file_size_limit
end

After("@project-fixtures") do
  Redcar::Project::Manager.reveal_files = true
  ProjectFixtureHelper.clear_project_fixtures
  DrbShelloutHelper.kill_thread
  Redcar::Project::Manager.file_size_limit = @original_file_size_limit
end
