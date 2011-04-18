
def runnable_fixtures
  File.expand_path(File.dirname(__FILE__) + "/../fixtures")
end

def runnable_config
  "#{runnable_fixtures}/.redcar/runnables/fixture_runnables.json"
end

def reset_runnable_fixtures
  # Not sure why this is needed, perhaps next test is starting before full deletion?
  FileUtils.rm_rf(runnable_fixtures)
  FileUtils.mkdir_p(runnable_fixtures)
  FileUtils.mkdir_p(File.dirname(runnable_config))

  File.open("#{runnable_fixtures}/runnable_app.rb", 'w') do |f|
    f.puts %Q|puts "hello world"|
  end

  File.open("#{runnable_fixtures}/params_app.rb", 'w') do |f|
    f.puts "ARGV.each { |it| print it+' '}"
  end

  File.open("#{runnable_fixtures}/alternate.ruby", 'w') do |f|
    f.puts "ARGV.each { |it| print it+' '}"
  end

  File.open("#{runnable_fixtures}/name_app.rb", 'w') do |f|
    f.puts "ARGV.each { |it| println it}"
  end

  File.open("#{runnable_fixtures}/line_app.rb", 'w') do |f|
    f.puts "ARGV.each { |it| println it}"
  end

  File.open(runnable_config, 'w') do |f|
    f.print <<-EOS
      {
        "commands":[
          {
            "name":        "An app",
            "command":     "jruby runnable_app.rb",
            "description": "Runs the app"
          },
          {
            "name":        "A silent app",
            "command":     "jruby runnable_app.rb",
            "description": "Runs the app silently",
            "output":      "none"
          },
          {
            "name":        "A windowed app",
            "command":     "jruby runnable_app.rb",
            "description": "Runs the app in a window",
            "output":      "window"
          },
          {
            "name":        "A params app",
            "command":     "jruby __PARAMS__",
            "description": "Runs the app with a parameter"
          },
          {
            "name":        "A multi-params app",
            "command":     "jruby params_app.rb __PARAMS__ __PARAMS__",
            "description": "Runs the app with many parameters"
          },
          {
            "name":        "An appendable app",
            "command":     "jruby params_app.rb hello",
            "description": "Runs an app that prints parameters"
          },
          {
            "name": "A nested app",
            "command": "echo 'lo'",
            "description": "A test for nesting",
            "type": "first/second"
          }
        ],
        "file_runners":[
          {
            "regex":   ".*\\\\name_app.rb",
            "name":    "Run as ruby",
            "command": "jruby \\"__PATH__\\" __NAME__",
            "type":    "app/ruby"
          },
          {
            "regex":   ".*\\\\.ruby",
            "name":    "Run as ruby",
            "command": "jruby \\"__PATH__\\" 1 2 3",
            "type":    "app/ruby"
          },
          {
            "regex":   ".*\\\\line_app.rb",
            "name":    "Run as ruby",
            "command": "jruby \\"__PATH__\\" __LINE__",
            "type":    "app/ruby"
          },
          {
            "regex":   ".*\\\\.rb",
            "name":    "Run as ruby",
            "command": "jruby \\"__PATH__\\"",
            "type":    "app/ruby"
          },
          {
            "regex":   ".*\\\\.ruby",
            "name":    "Run as ruby",
            "command": "jruby \\"__PATH__\\" hello world",
            "type":    "app/ruby"
          }
        ]
      }
    EOS
  end
end

Before("@runnables") do
  reset_runnable_fixtures
  Redcar.gui.dialog_adapter.clear_input
end

After("@runnables") do
  FileUtils.rm_rf runnable_fixtures
  Redcar.gui.dialog_adapter.clear_input
end
