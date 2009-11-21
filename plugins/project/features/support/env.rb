RequireSupportFiles File.dirname(__FILE__) + "/../../../edit_view/features/"

def reset_project_fixtures
  fixtures_path = File.expand_path(File.dirname(__FILE__) + "/../fixtures")
  File.open(fixtures_path + "/winter.txt", "w") {|f| f.print "Wintersmith" }
  FileUtils.rm_rf(fixtures_path + "/winter2.txt")
end

Before do
  reset_project_fixtures
end

After do
  reset_project_fixtures
end