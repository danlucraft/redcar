
desc "Run all features"
task :features do
  puts "Running all features"
  sh %{xvfb-run cucumber -p progress -r plugins/redcar/features/env.rb plugins/*/features/}
end

namespace :features do
  # Generate feature tasks for each plugin.
  Dir["plugins/*"].each do |fn|
    name = fn.split("/").last
    desc "Run features for #{name}"
    task name.intern do
      sh %{xvfb-run ./vendor/cucumber/bin/cucumber -p default -r plugins/redcar/features/env.rb plugins/#{name}/features/}
    end
  end
end
