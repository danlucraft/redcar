module TodoListSpecHelper
  Fixtures = File.expand_path("../project", __FILE__)

  def self.set_fixture_settings
    Redcar::TodoList.storage['tags'] = ["FIXME", "OPTIMIZE", "NOTE", "TODO"]
    Redcar::TodoList.storage['excluded_files'] = ["NOTE.ignored.file"]
    Redcar::TodoList.storage['require_colon'] = false
    Redcar::TodoList.storage['excluded_dirs'] = ["ignored_directory"]
    Redcar::TodoList.storage['included_suffixes'] = [".file"]
  end
end
