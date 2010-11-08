
def htmlview_fixtures_path
  File.expand_path(File.dirname(__FILE__) + "/../fixtures")
end

def htmlview_fixtures_redcar
  File.join(htmlview_fixtures_path,".redcar")
end

def reset_htmlview_fixtures
  FileUtils.rm_rf(htmlview_fixtures_redcar) if File.exists?(htmlview_fixtures_redcar)
  File.open(htmlview_fixtures_path + "/sample.html", "w") do |f|
    f.print "<html><b>Hello!!</b></html>"
  end
  File.open(htmlview_fixtures_path + "/other.html", "w") do |f|
    f.print "<html><b>Is today Tuesday?</b></html>"
  end
end

Before do
  reset_htmlview_fixtures
end

After do
  reset_htmlview_fixtures
end
