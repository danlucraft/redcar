
class ProjectFixtureHelper

  def self.fixtures_path
    File.expand_path(File.dirname(__FILE__) + "/fixtures")
  end
  
  def self.original_fixtures_path
    File.expand_path(File.dirname(__FILE__) + "/fixtures.orig")
  end
  
  def self.create_project_fixtures
    clear_project_fixtures
    FileUtils.cp_r(original_fixtures_path, fixtures_path)
  end
  
  def self.clear_project_fixtures
    FileUtils.rm_rf(fixtures_path)
  end
  
  def self.make_subproject_fixtures
    FileUtils.mkdir_p(fixtures_path + "/myproject/test1")
    FileUtils.mkdir_p(fixtures_path + "/myproject/test2")
    FileUtils.mkdir_p(fixtures_path + "/myproject/.redcar")
    File.open(fixtures_path + "/myproject/.redcar/test_config", "w") {|f| f.print "this is a config file" }
    File.open(fixtures_path + "/myproject/test1/a.txt", "w") {|f| f.print "this is a project file" }
    File.open(fixtures_path + "/myproject/test1/b.txt", "w") {|f| f.print "this is a project file" }
    File.open(fixtures_path + "/myproject/test1/c.txt", "w") {|f| f.print "this is a project file" }
  end
end
