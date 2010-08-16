RequireSupportFiles File.dirname(__FILE__) + "/../../../edit_view/features/"
RequireSupportFiles File.dirname(__FILE__) + "/../../../project/features/"

def runnable_fixtures
  File.expand_path(File.dirname(__FILE__) + "/../fixtures")
end

def runnable_config
  "#{runnable_fixtures}/.redcar/runnables/fixture_runnables.json"
end

def reset_runnable_fixtures
  # Not sure why this is needed, perhaps next test is starting before full deletion?
  FileUtils.rm_rf runnable_fixtures
  FileUtils.mkdir runnable_fixtures
  FileUtils.mkdir_p File.dirname(runnable_config)
  
  File.open("#{runnable_fixtures}/runnable_app.rb", 'w') do |f|
    f.puts %Q|puts "hello world"|
  end
  
  File.open(runnable_config, 'w') do |f|
    f.print <<-EOS.gsub(' ' * 6, '')
      {
        "commands":[
          {
            "name":        "An app",
            "command":     "ruby runnable_app.rb",
            "description": "Runs the app",
            "type":        "task/ruby"
          }
        ]
      }
    EOS
  end
end

Before do
  reset_runnable_fixtures
end

After do
  FileUtils.rm_rf runnable_fixtures
end