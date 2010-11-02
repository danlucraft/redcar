
def fixtures_path
  File.expand_path(File.dirname(__FILE__) + "/../../features/fixtures")
end

def bookmarks_file
  File.join(fixtures_path, ".redcar","web_bookmarks.json")
end

def bookmarks_backup
  File.join(fixtures_path, ".redcar","web_bookmarks.json.bak")
end

def reset_web_fixtures
  FileUtils.rm(bookmarks_file) if File.exist?(bookmarks_file)
  FileUtils.cp(bookmarks_backup,bookmarks_file)
  File.open(fixtures_path + "/sample.html", "w") do |f|
    f.print "<html><b>Hello!!</b></html>"
  end
  File.open(fixtures_path + "/other.html", "w") do |f|
    f.print "<html><b>Is today Tuesday?</b></html>"
  end
end

Before do
  reset_web_fixtures
end