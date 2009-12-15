
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

begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
    t.files   = [
        'plugins/*/lib/*.rb',
        'plugins/*/lib/**/*.rb'
      ]
    t.options = ['--markup', 'markdown']
  end  
rescue LoadError
end

task :yardoc do
  files = []
  %w(core application application_swt edit_view edit_view_swt project redcar).each do |plugin_name|
    files += Dir["plugins/#{plugin_name}/**/*.rb"]
  end
  %x(yardoc #{files.join(" ")} -o yardoc)
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

desc "Package jars and submodules into big tar file"
task :package do
  sh("COPYFILE_DISABLE=true \
      tar czvf redcar_jars.tar.gz \
          --exclude textmate/.git \
          --exclude **/._* \
          --exclude *.off \
      plugins/application_swt/vendor/swt/{osx64,linux,linux64,windows}/swt.jar \
      plugins/application_swt/vendor/jface/org.eclipse.*.jar \
      plugins/edit_view_swt/vendor/*.jar \
      plugins/edit_view_swt/vendor/java-mateview.rb \
      textmate/Bundles textmate/Themes"
  )
end


require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"

def remove_gitignored_files(filelist)
  ignores = File.readlines(".gitignore")
  ignores = ignores.select {|ignore| ignore.chomp.strip != ""}
  ignores = ignores.map {|ignore| Regexp.new(ignore.chomp.gsub(".", "\\.").gsub("*", ".*"))}
  r = filelist.select {|fn| not ignores.any? {|ignore| fn =~ ignore }}
  r.select {|fn| fn !~ /\.jar$/}
end

# This builds the actual gem. For details of what all these options
# mean, and other ones you can add, check the documentation here:
#
#   http://rubygems.org/read/chapter/20
#
spec = Gem::Specification.new do |s|
  
  # Change these as appropriate
  s.name              = "redcar"
  s.version           = "0.2.9dev"
  s.summary           = "A JRuby text editor. (Installing the gem will take a while as it downloads assets during the install.)"
  s.author            = "Daniel Lucraft"
  s.email             = "dan@fluentradical.com"
  s.homepage          = "http://redcareditor.com"

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README.md)
  s.rdoc_options      = %w(--main README.md)
  # s.platform          = 

  # Add any extra files to include in the gem
  s.files             = %w(CHANGES INSTALL.md LICENSE Rakefile README.md ROADMAP.md) + 
                          Dir.glob("bin/redcar") + 
                          Dir.glob("ext/**/*") + 
                          remove_gitignored_files(Dir.glob("lib/**/*")) + 
                          remove_gitignored_files(Dir.glob("plugins/**/*")) + 
                          Dir.glob("textmate/Bundles/*.tmbundle/**/*") + 
                          Dir.glob("textmate/Themes/*.tmTheme")
  s.executables       = FileList["bin/redcar"].map { |f| File.basename(f) }
   
  s.require_paths     = ["lib"]
  
  # If you want to depend on other gems, add them here, along with any
  # relevant versions
  # s.add_dependency("logging", "> 1.0.0")
  
  # If your tests use any gems, include them here
  s.add_development_dependency("cucumber")
  s.add_development_dependency("rspec")
  
  
  s.extensions = ["ext/extconf.rb"]
end

# This task actually builds the gem. We also regenerate a static 
# .gemspec file, which is useful if something (i.e. GitHub) will
# be automatically building a gem for this project. If you're not
# using GitHub, edit as appropriate.
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
  
  # Generate the gemspec file for github.
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

# Generate documentation
Rake::RDocTask.new do |rd|
  rd.main = "README.md"
  rd.rdoc_files.include("README.md", "lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_package] do
  rm "#{spec.name}.gemspec"
end
