
# To create Rake tasks for your plugin, put them in plugins/my_plugin/Rakefile or
# plugins/my_plugin/tasks/my_tasks.rake.

require 'rubygems'
require 'fileutils'
require 'spec/rake/spectask'
require 'cucumber/rake/task'

if RUBY_PLATFORM =~ /mswin/
  begin
    require 'win32console'
  rescue LoadError
    ARGV << "--nocolour"
  end
end

GREEN_FG = "\033[1;32m"
RED_FG = "\033[1;31m"
RED_BG = "\033[1;37m\033[41m"
GREY_BG = "\033[40m"
BLUE_FG = "\033[1;34m"
CLEAR_COLOURS = "\033[0m"

def execute_and_check(command)
  puts %x{#{command}}
  $?.to_i == 0 ? true : raise
end

def execute(command)
  puts %x{#{command}}
  $?.to_i == 0 ? true : false
end

def plugin_names
  Dir["plugins/*"].map do |fn|
    name = fn.split("/").last
  end
end

Dir[File.join(File.dirname(__FILE__), *%w[plugins *])].each do |plugin_dir|
  rakefiles = [File.join(plugin_dir, "Rakefile")] + 
    Dir[File.join(plugin_dir, "tasks", "*.rake")]
  rakefiles.each do |rakefile|
    if File.exist?(rakefile)
      load rakefile
    end
  end
end

task :yardoc do
  files = []
  %w(core application application_swt edit_view edit_view_swt redcar).each do |plugin_name|
    files += Dir["plugins/#{plugin_name}/**/*.rb"]
  end
  %x(yardoc #{files.join(" ")} -o yardoc)
end

task :clear_cache do
  sh "rm cache/*/*.dump"
end

desc "list all tasks"
task :list do
  Rake::Task.tasks.each do |task|
    puts "rake #{task.name}"
  end
end

desc "Run all specs and features"
task :default => ["specs", "cucumber"]

desc "Run features"
task :cucumber do
  sh("jruby -J-XstartOnFirstThread bin/cucumber -cf progress plugins/*/features && echo 'done'")
end

Spec::Rake::SpecTask.new("specs") do |t|
  t.spec_files = FileList[
    'plugins/*/spec/*/*_spec.rb',
    'plugins/*/spec/*/*/*_spec.rb',
    'plugins/*/spec/*/*/*/*_spec.rb',
  ]
  t.spec_opts = ["-c"]
end




