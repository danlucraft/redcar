
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

require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files   = [
      'lib/*.rb', 
      'plugins/*/lib/*.rb',
      'plugins/*/lib/**/*.rb'
    ]
  t.options = ['--markup', 'markdown']
end

task :yardoc do
  files = []
  %w(core application application_swt edit_view edit_view_swt project redcar).each do |plugin_name|
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
  case Config::CONFIG["host_os"]
  when "darwin"
    sh("jruby -J-XstartOnFirstThread bin/cucumber -cf progress plugins/*/features && echo 'done'")
  else
    sh("jruby bin/cucumber -cf progress plugins/*/features && echo 'done'")
  end
end

Spec::Rake::SpecTask.new("specs") do |t|
  t.spec_files = FileList[
    'plugins/*/spec/*/*_spec.rb',
    'plugins/*/spec/*/*/*_spec.rb',
    'plugins/*/spec/*/*/*/*_spec.rb',
  ]
  t.spec_opts = ["-c"]
end

desc "Build"
task :build do
  sh("ant jar -f vendor/java-mateview/build.xml")
  cp("vendor/java-mateview/lib/java-mateview.rb", "plugins/edit_view_swt/vendor/")
  cp("vendor/java-mateview/release/java-mateview.jar", "plugins/edit_view_swt/vendor/")
  Dir["vendor/java-mateview/lib/*.jar"].each do |fn|
    FileUtils.cp(fn, "plugins/edit_view_swt/vendor/")
  end
end



