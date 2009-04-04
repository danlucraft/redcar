
# To create Rake tasks for your plugin, put them in plugins/my_plugin/Rakefile or
# plugins/my_plugin/tasks/my_tasks.rake.

require 'rubygems'
require 'fileutils'

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

def cputs(text, colours, opts={})
  colours.each {|colour| print colour }
  print text
  if opts[:no_newline]
    print CLEAR_COLOURS
  else
    puts CLEAR_COLOURS
  end
end

include FileUtils

cd(File.dirname(__FILE__))

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

task :clear_cache do
  sh "rm cache/*/*.dump"
end

desc "list all tasks"
task :list do
  Rake::Task.tasks.each do |task|
    puts "rake #{task.name}"
  end
end

