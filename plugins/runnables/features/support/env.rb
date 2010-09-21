RequireSupportFiles File.dirname(__FILE__) + "/../../../application/features/"
RequireSupportFiles File.dirname(__FILE__) + "/../../../edit_view/features/"
RequireSupportFiles File.dirname(__FILE__) + "/../../../html_view/features/"
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
  FileUtils.mkdir_p runnable_fixtures
  FileUtils.mkdir_p File.dirname(runnable_config)

  File.open("#{runnable_fixtures}/runnable_app.rb", 'w') do |f|
    f.puts %Q|puts "hello world"|
  end

  File.open("#{runnable_fixtures}/params_app.rb", 'w') do |f|
    #f.puts "puts ARGV[0] +' '+ ARGV[1]"
    f.puts "ARGV.each { |it| print it+' '}"
  end

  File.open(runnable_config, 'w') do |f|
    f.print <<-EOS
      {
        "commands":[
          {
            "name":        "An app",
            "command":     "jruby runnable_app.rb",
            "description": "Runs the app",
            "type":        "task/ruby"
          },
          {
            "name":        "A silent app",
            "command":     "jruby runnable_app.rb",
            "description": "Runs the app silently",
            "type":        "task/ruby",
            "output":      "none"
          },
          {
            "name":        "A windowed app",
            "command":     "jruby runnable_app.rb",
            "description": "Runs the app in a window",
            "type":        "task/ruby",
            "output":      "window"
          },
          {
            "name":        "A params app",
            "command":     "jruby __PARAMS__",
            "description": "Runs the app with a parameter",
            "type":        "task/ruby"
          },
          {
            "name":        "A multi-params app",
            "command":     "jruby params_app.rb __PARAMS__ __PARAMS__",
            "description": "Runs the app with many parameters",
            "type":        "task/ruby"
          },
          {
            "name":        "An appendable app",
            "command":     "jruby params_app.rb hello",
            "description": "Runs an app that prints parameters",
            "type":        "task/ruby"
          }
        ],
        "file_runners":[
          {
            "regex":   ".*\\\\.rb",
            "name":    "Run as ruby",
            "command": "jruby \\"__PATH__\\"",
            "type":    "app/ruby"
          }
        ]
      }
    EOS
  end
end

Before do
  reset_runnable_fixtures
  Redcar.gui.dialog_adapter.clear_input
end

After do
  FileUtils.rm_rf runnable_fixtures
  Redcar.gui.dialog_adapter.clear_input
end
