REDCAR_VERSION = "0.3.8dev"

require 'rubygems'
require 'fileutils'
require 'spec/rake/spectask'
require 'cucumber/rake/task'
require "rake/gempackagetask"
require "rake/rdoctask"

if RUBY_PLATFORM =~ /mswin|mingw/
  begin
    # not available for jruby yet
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

### CI
task :ci => [:specs_ci, :cucumber_ci]

def find_ci_reporter(filename)
  jruby_gem_path = %x[jruby -rubygems -e "p Gem.path.first"].gsub("\n", "").gsub('"', "")
  result = Dir.glob("#{jruby_gem_path}/gems/ci_reporter-*/lib/ci/reporter/rake/#{filename}.rb").reverse.first
  result || raise("Could not find ci_reporter gem in #{jruby_gem_path}")
end

task :specs_ci do
  rspec_loader = find_ci_reporter "rspec_loader"  
  files = Dir['plugins/*/spec/*/*_spec.rb'] + Dir['plugins/*/spec/*/*/*_spec.rb'] + Dir['plugins/*/spec/*/*/*/*_spec.rb']
  opts = "-J-XstartOnFirstThread" if Config::CONFIG["host_os"] =~ /darwin/
  opts = "#{opts} -S spec --require #{rspec_loader} --format CI::Reporter::RSpec -c #{files.join(" ")}"
  sh("jruby #{opts} && echo 'done'")
end

task :cucumber_ci do
  cucumber_loader = find_ci_reporter "cucumber_loader"
  opts = "-J-XstartOnFirstThread" if Config::CONFIG["host_os"] =~ /darwin/
  opts = "#{opts} -r #{cucumber_loader} -S bin/cucumber --format CI::Reporter::Cucumber plugins/*/features"
  sh("jruby #{opts} && echo 'done'")
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
  sh "ant jar -f vendor/java-mateview/build.xml"
  cp "vendor/java-mateview/lib/java-mateview.rb", "plugins/edit_view_swt/vendor/"
  cp "vendor/java-mateview/release/java-mateview.jar", "plugins/edit_view_swt/vendor/"
  cd "plugins/application_swt" do
    sh "ant"
  end
end

def remove_gitignored_files(filelist)
  ignores = File.readlines(".gitignore")
  ignores = ignores.select {|ignore| ignore.chomp.strip != ""}
  ignores = ignores.map {|ignore| Regexp.new(ignore.chomp.gsub(".", "\\.").gsub("*", ".*"))}
  r = filelist.select {|fn| not ignores.any? {|ignore| fn =~ ignore }}
  r.select {|fn| fn !~ /\.git/ }
end

spec = Gem::Specification.new do |s|
  s.name              = "redcar"
  s.version           = REDCAR_VERSION
  s.summary           = "A JRuby text editor."
  s.author            = "Daniel Lucraft"
  s.email             = "dan@fluentradical.com"
  s.homepage          = "http://redcareditor.com"

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README.md)
  s.rdoc_options      = %w(--main README.md)

  s.files             = %w(CHANGES LICENSE Rakefile README.md ROADMAP.md) + 
                          Dir.glob("bin/redcar") + 
                          Dir.glob("config/**/*") + 
                          remove_gitignored_files(Dir.glob("lib/**/*")) + 
                          remove_gitignored_files(Dir.glob("plugins/**/*")) + 
                          Dir.glob("textmate/Bundles/*.tmbundle/Syntaxes/**/*") + 
                          Dir.glob("textmate/Bundles/*.tmbundle/Preferences/**/*") + 
                          Dir.glob("textmate/Bundles/*.tmbundle/Snippets/**/*") + 
                          Dir.glob("textmate/Bundles/*.tmbundle/info.plist") + 
                          Dir.glob("textmate/Themes/*.tmTheme")
  s.executables       = FileList["bin/redcar"].map { |f| File.basename(f) }
   
  s.require_paths     = ["lib"]

  s.add_dependency("rubyzip")
  
  s.add_development_dependency("cucumber")
  s.add_development_dependency("rspec")
  s.add_development_dependency("watchr")
  
  s.post_install_message = <<TEXT

------------------------------------------------------------------------------------

Please now run:

  $ redcar install

to complete the installation. 

(If you installed the gem with 'sudo', you will need to run 'sudo redcar install').

NB. This will download jars that Redcar needs to run from the internet. It will put
them only into the Redcar gem directory.

------------------------------------------------------------------------------------

TEXT
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Build a MacOS X App bundle"
task :app_bundle => :build do
  require 'erb'

  redcar_icon = "redcar_icon_beta.png"

  bundle_contents = File.join("pkg", "Redcar.app", "Contents")
  FileUtils.rm_rf bundle_contents if File.exist? bundle_contents
  macos_dir = File.join(bundle_contents, "MacOS")
  resources_dir = File.join(bundle_contents, "Resources")
  FileUtils.mkdir_p macos_dir
  FileUtils.mkdir_p resources_dir

  info_plist_template = ERB.new <<-PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>redcar</string>
	<key>CFBundleIconFile</key>
	<string><%= redcar_icon %></string>
	<key>CFBundleIdentifier</key>
	<string>com.redcareditor.Redcar</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string><%= spec.version %></string>
	<key>LSMinimumSystemVersion</key>
	<string>10.5</string>
</dict>
</plist>
  PLIST
  File.open(File.join(bundle_contents, "Info.plist"), "w") do |f|
    f << info_plist_template.result(binding)
  end

  File.open(File.join(macos_dir, "redcar"), "w") do |f|
    f << '#!/bin/sh
          DIR=$(cd "$(dirname "$0")"; pwd)
          REDCAR=$(cd "$(dirname "${DIR}/../Resources/bin/redcar")"; pwd)
          $REDCAR/redcar --ignore-stdin $@'
  end
  File.chmod 0777, File.join(macos_dir, "redcar")

  spec.files.each do |f|
    FileUtils.mkdir_p File.join(resources_dir, File.dirname(f))
    FileUtils.cp_r f, File.join(resources_dir, f), :remove_destination => true
  end

  p "Running #{File.join(resources_dir, "bin", "redcar")} install"
  system "#{File.join(resources_dir, "bin", "redcar")} install"

  FileUtils.cp_r File.join(resources_dir, "plugins", "application", "icons", redcar_icon), 
      resources_dir, :remove_destination => true
end

desc 'Clean up (sanitize) the Textmate files for packaging'
task :clean_textmate do
  # rename files to be x-platform safe
  Dir["textmate/Bundles/*.tmbundle/*/**/*"].each do |fn|
    if File.file?(fn)
      bits = fn.split("/").last.split(".")[0..-2].join("_")
      new_basename = bits.gsub(" ", "_").gsub(/[^\w_]/, "__").gsub(/\\./, "__") + File.extname(fn)
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

desc "Release gem"
task :release => :gem do
  require 'aws/s3'
  credentials = YAML.load(File.read("/Users/danlucraft/.s3-creds.yaml"))
  AWS::S3::Base.establish_connection!(
    :access_key_id     => credentials['access_key_id'],
    :secret_access_key => credentials["secret_access_key"]
  )
  
  redcar_bucket = AWS::S3::Bucket.find('redcar')
  
  file = "plugins/edit_view_swt/vendor/java-mateview.jar"
  AWS::S3::S3Object.store("java-mateview-#{REDCAR_VERSION}.jar", open(file), 'redcar', :access => :public_read)
  
  file = "plugins/application_swt/lib/dist/application_swt.jar"
  AWS::S3::S3Object.store("application_swt-#{REDCAR_VERSION}.jar", open(file), 'redcar', :access => :public_read)
  
  file = "pkg/redcar-#{REDCAR_VERSION}.gem"
  AWS::S3::S3Object.store("redcar-#{REDCAR_VERSION}.gem", open(file), 'redcar', :access => :public_read)
end

def hash_with_hash_default
  Hash.new {|h,k| h[k] = hash_with_hash_default }
end

namespace :redcar do
  desc "Redcar Integration: output runnable info"
  task :runnables do
    mkdir_p(".redcar")
    puts "Creating runnables"
    
    tasks = Rake::Task.tasks
    bin = File.join(Config::CONFIG["bindir"], "rake")
    runnables = hash_with_hash_default
    tasks.each do |task|
      bits = task.name.split(":")
      namespace = runnables
      while bits.length > 1
        namespace = namespace[bits.shift]
      end
      command = bin + " " + task.name
      namespace[bits.shift] = {:command => command, :desc => task.comment}
    end
    File.open(".redcar/runnables", "w") do |f|
      f.puts runnables.to_yaml
    end
  end
  
  task :sample do
    puts "out1"
sleep 1
$stderr.puts "err1"
sleep 1
puts "out2"
sleep 1
$stderr.puts "err2"
sleep 1
  end
end








