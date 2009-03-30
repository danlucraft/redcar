
# To create Rake tasks for your plugin, put them in plugins/my_plugin/Rakefile or
# plugins/my_plugin/tasks/my_tasks.rake.

require 'rubygems'
require 'fileutils'

include FileUtils

cd(File.dirname(__FILE__))

def execute_and_check(command)
  puts %x{#{command}}
  $?.to_i == 0 ? true : raise
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

task :coredoc2 do
  FileUtils.rm_rf "doc"
  FileUtils.mkdir "tmpfordoc"
  Dir["plugins/core/*"].each do |fn|
    if File.file? fn
      FileUtils.cp fn, "tmpfordoc/"+fn.split("/").last
    end
  end
  sh "rdoc -T jamis tmpfordoc/"
  FileUtils.rm_rf "tmpfordoc"
end

task :coredoc do
  FileUtils.rm_rf "doc"
  files = Dir["plugins/core/lib/*"].select{|f| File.file? f}
  sh "rdoc -T jamis #{files.join(" ")} README.txt"
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

