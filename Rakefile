
require 'rubygems'
require 'fileutils'
require 'spec/rake/spectask'
require 'cucumber/rake/task'
require "rake/gempackagetask"
require "rake/rdoctask"

if RUBY_PLATFORM =~ /mswin/
  begin
    require 'win32console'
  rescue LoadError
    ARGV << "--nocolour"
  end
end

### DOCUMENTATION

begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
    t.files   = [
        'lib/*.rb',
        'lib/*/*.rb',
        'plugins/*/lib/*.rb',
        'plugins/*/lib/**/*.rb'
      ]
    t.options = ['--markup', 'markdown']
  end  
rescue LoadError
end

### TESTS

desc "Run all specs and features"
task :default => ["specs", "cucumber"]

task :specs do
  files = Dir['plugins/*/spec/*/*_spec.rb'] + Dir['plugins/*/spec/*/*/*_spec.rb'] + Dir['plugins/*/spec/*/*/*/*_spec.rb']
  case Config::CONFIG["host_os"]
  when "darwin"
    sh("jruby -J-XstartOnFirstThread -S spec -c #{files.join(" ")} && echo 'done'")
  else
    sh("jruby -S spec -c #{files.join(" ")} && echo 'done'")
  end
end

desc "Run features"
task :cucumber do
  case Config::CONFIG["host_os"]
  when "darwin"
    sh("jruby -J-XstartOnFirstThread bin/cucumber -cf progress plugins/*/features && echo 'done'")
  else
    sh("jruby bin/cucumber -cf progress plugins/*/features && echo 'done'")
  end
end

### BUILD AND RELEASE

desc "Build"
task :build do
  sh("ant jar -f vendor/java-mateview/build.xml")
  cp("vendor/java-mateview/lib/java-mateview.rb", "plugins/edit_view_swt/vendor/")
  cp("vendor/java-mateview/release/java-mateview.jar", "plugins/edit_view_swt/vendor/")
end

def remove_gitignored_files(filelist)
  ignores = File.readlines(".gitignore")
  ignores = ignores.select {|ignore| ignore.chomp.strip != ""}
  ignores = ignores.map {|ignore| Regexp.new(ignore.chomp.gsub(".", "\\.").gsub("*", ".*"))}
  r = filelist.select {|fn| not ignores.any? {|ignore| fn =~ ignore }}
  r.select {|fn| fn !~ /\.jar$/}
end

spec = Gem::Specification.new do |s|
  
  # Change these as appropriate
  s.name              = "redcar"
  s.version           = "0.3.2"
  s.summary           = "A JRuby text editor."
  s.author            = "Daniel Lucraft"
  s.email             = "dan@fluentradical.com"
  s.homepage          = "http://redcareditor.com"

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README.md)
  s.rdoc_options      = %w(--main README.md)
  # s.platform          = 

  # Add any extra files to include in the gem
  s.files             = %w(CHANGES LICENSE Rakefile README.md ROADMAP.md) + 
                          Dir.glob("bin/redcar") + 
                          Dir.glob("config/**/*") + 
                          remove_gitignored_files(Dir.glob("lib/**/*")) + 
                          remove_gitignored_files(Dir.glob("plugins/**/*")) + 
                          Dir.glob("textmate/Bundles/*.tmbundle/Syntaxes/**/*") + 
                          Dir.glob("textmate/Themes/*.tmTheme")
  s.executables       = FileList["bin/redcar"].map { |f| File.basename(f) }
   
  s.require_paths     = ["lib"]

  # If you want to depend on other gems, add them here, along with any
  # relevant versions
  # s.add_dependency("logging", "> 1.0.0")
  
  # If your tests use any gems, include them here
  s.add_development_dependency("cucumber")
  s.add_development_dependency("rspec")
  s.add_development_dependency("watchr")
  
  s.post_install_message = <<TEXT

------------------------------------------------------------------------------------

Please now run:

  $ redcar install

to complete the installation. 

(If you installed the gem with 'sudo', you will need to run 'sudo redcar install').

------------------------------------------------------------------------------------

TEXT
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc 'Clean up (sanitize) the Textmate files for packaging'
task :clean_textmate do
  # rename files to be x-platform safe
  Dir["textmate/Bundles/*.tmbundle/{Syntaxes,Snippets,Templates}/**/*"].each do |fn|
    if File.file?(fn)
      bits = fn.split("/").last.split(".")[0..-2].join("_")
      new_basename = bits.gsub(" ", "_").gsub(/[^\w_]/, "__") + File.extname(fn)
      new_fn = File.join(File.dirname(fn), new_basename)
      # p [fn,new_fn]
      next if new_fn == fn
      if File.exist?(new_fn)
        puts "already exists #{new_fn}"
        new_fn = File.join(File.dirname(fn), "next_" + new_basename)
        unless File.exist?(new_fn)
          FileUtils.mv(fn, new_fn)
        end
      else
        begin
          FileUtils.mv(fn, new_fn)
        rescue => e
          puts e
        end
      end
    end
  end
end

desc 'Run a watchr continuous integration daemon for the specs'
task :run_ci do
  require 'watchr'
  script = Watchr::Script.new
  script.watch(/.*\/([^\/]+).rb$/) { |filename|
    if filename[0] =~ /_spec\.rb/ # a spec file
      a = "jruby -S spec #{filename} --backtrace"
      puts a
      system a
    end  
  
    spec_filename = "#{filename[1]}_spec.rb"
    spec = Dir["**/#{spec_filename}"]
    if spec.length > 0
     a = "jruby -S spec #{spec[0]}"
     puts a
     system a
    end
  }
  contrl = Watchr::Controller.new(script, Watchr.handler.new)
  contrl.run
end

