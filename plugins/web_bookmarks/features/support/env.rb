
def web_fixtures_path
  File.expand_path(File.dirname(__FILE__) + "/../../features/fixtures")
end

def bookmarks_file
  File.join(web_fixtures_path, ".redcar","web_bookmarks.json")
end

def bookmarks_backup
  File.join(web_fixtures_path, ".redcar","web_bookmarks.json.bak")
end

def reset_web_fixtures
  FileUtils.rm(bookmarks_file) if File.exist?(bookmarks_file)
  FileUtils.cp(bookmarks_backup,bookmarks_file)
end

Before do
  reset_web_fixtures
end

After do
  reset_web_fixtures
  FileUtils.rm(bookmarks_file) if File.exist?(bookmarks_file)
end
