REDCAR_VERSION     = "0.14.0dev"
REDCAR_DESCRIPTION = "A Ruby programmer's text editor"
REDCAR_MAINTAINER  = "Daniel Lucraft <dan@fluentradical.com>"
REDCAR_LICENSE     = "GPL v2"
REDCAR_VENDOR      = "n/a"
REDCAR_URL         = "http://redcareditor.com"

JRUBY_JAR_LOCATION = "http://jruby.org.s3.amazonaws.com/downloads/1.6.7/jruby-complete-1.6.7.jar"
REDCAR_ROOT        = File.expand_path("../", __FILE__)

require 'fileutils'
require 'net/http'
require 'json'

Dir[File.expand_path("../lib/tasks/*.rake", __FILE__)].each { |f| load f }

if RUBY_PLATFORM =~ /mswin|mingw/
  begin
    # not available for jruby yet
    require 'win32console'
  rescue LoadError
    ARGV << "--nocolour"
  end
end


desc "Download dependencies"
task :init do
  vendor = File.join(REDCAR_ROOT, "vendor")
  sh("curl -L #{JRUBY_JAR_LOCATION} > #{vendor}/jruby-complete.jar")

  github_exts = {
    "mscharley/ruby-git" => "git"
  }

  gems = [
  # "git",
  # "spoon",
  "lucene", #"~> 0.5.0.beta.1",
  "jruby-openssl",
  "ruby-blockcache",
  "bouncy-castle-java",
  "swt",
  "plugin_manager",
  "redcar-xulrunner-win",
  "zip"
  ]#, ">= 1.5")

  github_exts.each do |repo,reponame|
    target = File.join(vendor,reponame)
    unless File.exists?(target)
      sh("git clone https://github.com/#{repo}.git #{target}")
    end
  end

  gems.each do |gem_name|
    puts "fetching #{gem_name}"
    data = JSON.parse(Net::HTTP.get(URI.parse("http://rubygems.org/api/v1/gems/#{gem_name}.json")))
    gem_file = "#{vendor}/#{gem_name}-#{data["version"]}.gem"
    sh("curl -L #{data["gem_uri"]} > #{gem_file}")
    gem_dir = "#{vendor}/#{gem_name}"
    rm_rf(gem_dir)
    mkdir_p(gem_dir)
    sh("tar xv -C #{gem_dir} -f #{gem_file}")
    rm(gem_file)
    sh("tar xzv -C #{gem_dir} -f #{gem_dir}/data.tar.gz")
    rm("#{gem_dir}/data.tar.gz")
    rm("#{gem_dir}/metadata.gz")
  end
  sh("cd #{vendor}/redcar-xulrunner-win/vendor; unzip xulrunner*.zip; cd ../../../")
end

namespace :installers do
  desc "Package for Windows"
  task :win do
    win_dir = REDCAR_ROOT + "/pkg/win"
    rm_rf(win_dir)
    mkdir_p(win_dir)
    mkdir_p(win_dir)
    copy_all(win_dir)
    cp(REDCAR_ROOT + "/assets/redcar_win.exe", win_dir + "/redcar.exe")
    chmod(0755, "#{win_dir}/redcar.exe")
    sh("cd pkg/win; zip -r redcar-#{REDCAR_VERSION}.zip *; cd ../../; mv pkg/win/redcar-#{REDCAR_VERSION}.zip pkg/")
  end

  desc "Generate a debian package (uses fpm)"
  task :deb do
    deb_dir = REDCAR_ROOT + "/pkg/deb"
    rm_rf(deb_dir)
    rm_rf(REDCAR_ROOT + "/pkg/*.deb")
    mkdir_p("#{deb_dir}")
    mkdir_p("#{deb_dir}/bin")
    mkdir_p("#{deb_dir}/lib/redcar")
    copy_all("#{deb_dir}/lib/redcar")
    cp(REDCAR_ROOT + "/assets/redcar_linux.sh", "#{deb_dir}/bin/redcar")
    chmod(0755, "#{deb_dir}/bin/redcar")
    sh("fpm -a all -v #{REDCAR_VERSION} -s dir -t deb -n redcar --prefix /usr/local -C pkg/deb --url \"#{REDCAR_URL}\" --license \"#{REDCAR_LICENSE}\" --vendor \"#{REDCAR_VENDOR}\" --maintainer \"#{REDCAR_MAINTAINER}\" --description \"#{REDCAR_DESCRIPTION}\" bin lib")
    mv("redcar_#{REDCAR_VERSION}_all.deb", "pkg/")
  end

  desc "Generate an OSX app-bundle"
  task :osx do
    rm_rf(REDCAR_ROOT + "/pkg/Redcar.app")
    mkdir_p(REDCAR_ROOT + "/pkg/Redcar.app")
    bundle_content_dir = REDCAR_ROOT + "/pkg/Redcar.app/Contents"
    mkdir_p(bundle_content_dir)
    mkdir_p("#{bundle_content_dir}/MacOS")
    mkdir_p("#{bundle_content_dir}/Resources")

    info_plist = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>redcar.sh</string>
	<key>CFBundleIconFile</key>
	<string>redcar-icon-beta-dev.icns</string>
	<key>CFBundleIdentifier</key>
	<string>com.redcareditor.Redcar</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string></string>
	<key>LSMinimumSystemVersion</key>
	<string>10.5</string>
</dict>
</plist>
XML
    File.open(File.join(bundle_content_dir, "Info.plist"), "w") {|f| f.puts info_plist}
    cp(REDCAR_ROOT + "/assets/redcar_osx.sh", bundle_content_dir + "/MacOS/redcar.sh")
    cp(REDCAR_ROOT + "/assets/redcar-icons/redcar-icon-beta-dev.icns", bundle_content_dir + "/Resources")
    copy_all(bundle_content_dir + "/MacOS/")
    chmod(0755, bundle_content_dir + "/MacOS/redcar.sh")
    sh("cd pkg; zip -r Redcar-#{REDCAR_VERSION}.app.zip Redcar.app; cd ../")
    rm_r("pkg/Redcar.app")
  end

  def copy_all(target)
    exclude = [/pkg/, /spec/, /\.git/, /\.redcar/, /\.gemspec/, /\.yardoc/, /doc/]
    Dir.glob(REDCAR_ROOT + "/*").each do |item|
      unless exclude.any? {|re| re =~ item}
        sh("cp -r #{item} #{target}")
      end
    end
    rm_rf(target + "/javamateview/bin/com")
    rm_rf(target + "/vendor/swt/.git")
    clean(target)
  end

  def clean(target)
    Dir.glob(target + "/*", File::FNM_DOTMATCH).each do |item|
      next if [".", ".."].include?(File.basename(item))
      if [".redcar", ".DS_Store"].include? File.basename(item) or
          File.symlink?(item)
        rm_rf(item)
      elsif File.directory?(item)
        clean(item)
      end
    end
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

desc "upload the docs to redcareditor.com"
task :release_docs do
  port     = YAML.load(File.read(".server.yaml"))["port"]
  docs_dir = YAML.load(File.read(".server.yaml"))["dir"]
  sh "rsync -e 'ssh -p #{port}' -avz doc/ danlucraft.com:#{docs_dir}/#{REDCAR_VERSION}/"
  sh "rsync -e 'ssh -p #{port}' -avz doc/ danlucraft.com:#{docs_dir}/latest/"
end

def jruby_run(cmd)
  opts = "-J-XstartOnFirstThread" if Config::CONFIG["host_os"] =~ /darwin/
  sh("jruby --debug #{opts} -S #{cmd}; echo 'done'")
end

### CI
namespace :ci do
  def rspec(options = "")
    files = Dir['plugins/*/spec/*/*_spec.rb'] + Dir['plugins/*/spec/*/*/*_spec.rb'] + Dir['plugins/*/spec/*/*/*/*_spec.rb']
    rspec_opts = "#{options} -c #{files.join(" ")}"
    "$GEM_HOME/bin/spec #{rspec_opts}"
  end

  def cucumber(options = "")
    "bin/cucumber #{options} plugins/*/features"
  end

  namespace :rcov do
    COVERAGE_DATA = "coverage.data"

    def rcov_run(cmd, opts)
      excluded_files = "jsignal_internal,(erb),features/,spec/,vendor/,openssl/,yaml/,json/,yaml,gems,file:,(eval),(__FORWARDABLE__)"
      cmd = %{rcov --aggregate #{COVERAGE_DATA} -x "#{excluded_files}" #{cmd} -- #{opts}}
      jruby_run(cmd)
    end

    desc "Run the coverage task for specs"
    task :specs do
      cmd = rspec
      cmd, opts = cmd.split.first, cmd.split[1..-1].join(" ")
      rcov_run(cmd, opts)
    end

    desc "Run the coverage task for features"
    task :cucumber do
      cmd = cucumber
      cmd, opts = cmd.split.first, cmd.split[1..-1].join(" ")
      rcov_run(cmd, opts)
    end
  end

  desc "Run the coverage task"
  task :rcov do
    FileUtils.rm COVERAGE_DATA if File.exist?(COVERAGE_DATA)
    Rake::Task["ci:rcov:specs"].invoke
    Rake::Task["ci:rcov:cucumber"].invoke
  end

  def find_ci_reporter(filename)
    jruby_gem_path = %x[jruby -rubygems -e "p Gem.path.first"].gsub("\n", "").gsub('"', "")
    result = Dir.glob("#{jruby_gem_path}/gems/ci_reporter-*/lib/ci/reporter/rake/#{filename}.rb").reverse.first
    result || raise("Could not find ci_reporter gem in #{jruby_gem_path}")
  end

  desc "Run the specs with JUnit output for the Hudson reporter"
  task :specs do
    rspec_loader = find_ci_reporter "rspec_loader"
    rspec_opts = "--require #{rspec_loader} --format CI::Reporter::RSpec"
    jruby_run(rspec(rspec_opts))
  end

  desc "Run the features with JUnit output for the Hudson reporter"
  task :cucumber do
    reports_folder = "features/reports"
    FileUtils.rm_rf reports_folder if File.exist? reports_folder
    jruby_run(cucumber("-f progress -f junit --out #{reports_folder}"))
  end
end

desc "Run specs and features with JUnit output"
task :ci do
  Rake::Task["ci:specs"].invoke
  Rake::Task["ci:cucumber"].invoke
end


### TESTS

desc "Run all specs and features"
task :default => ["specs", "cucumber"]

desc "Run all specs"
task :specs do
  plugin_spec_dirs = Dir["plugins/*/spec"]
  sh("jruby -S bundle exec rspec -c #{plugin_spec_dirs.join(" ")}")
end

desc "Run all features"
task :cucumber do
  cmd = "jruby "
  cmd << "-J-XstartOnFirstThread " if Config::CONFIG["host_os"] =~ /darwin/
  all_feature_dirs = Dir['plugins/*/features'] # overcome a jruby windows bug http://jira.codehaus.org/browse/JRUBY-4527
  cmd << "bin/cucumber -cf progress -e \".*fixtures.*\" #{all_feature_dirs.join(' ')}"
  sh("#{cmd} && echo 'done'")
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
  cp "plugins/edit_view_swt/vendor/java-mateview.jar", "#{ENV['HOME']}/.redcar/assets/java-mateview-#{REDCAR_VERSION}.jar"
  cp "plugins/application_swt/lib/dist/application_swt.jar", "#{ENV['HOME']}/.redcar/assets/application_swt-#{REDCAR_VERSION}.jar"
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

namespace :redcar do
  def hash_with_hash_default
    Hash.new {|h,k| h[k] = hash_with_hash_default }
  end

  require 'json'

  desc "Redcar Integration: output runnable info"
  task :runnables do
    mkdir_p(".redcar/runnables")
    puts "Creating runnables"
    File.open(".redcar/runnables/sync_stdout.rb", "w") do |fout|
      fout.puts <<-RUBY
        $stdout.sync = true
        $stderr.sync = true
      RUBY
    end

    tasks = Rake::Task.tasks
    runnables = []
    ruby_bin = Config::CONFIG["bindir"] + "/ruby -r#{File.dirname(__FILE__)}/.redcar/runnables/sync_stdout.rb "
    tasks.each do |task|
      name = task.name.gsub(":", "/")
      command = ruby_bin + $0 + " " + task.name
      runnables << {
        "name"        => name,
        "command"     => command,
        "description" => task.comment,
        "type"        => "task/ruby/rake"
      }
    end
    File.open(".redcar/runnables/rake.json", "w") do |f|
      data = {"commands" => runnables}
      f.puts(JSON.pretty_generate(data))
    end
    File.open(".redcar/runnables/ruby.json", "w") do |f|
      data = {"file_runners" =>
        [
          {
            "regex" =>    ".*.rb$",
            "name" =>     "Run as ruby",
            "command" =>  ruby_bin + "__PATH__",
            "type" =>     "script/ruby"
          }
        ]
      }
      f.puts(JSON.pretty_generate(data))
    end
  end

  task :sample do
    5.times do |i|
      puts "out#{i}"
      sleep 1
      $stderr.puts "err#{i}"
      sleep 1
    end
    FileUtils.touch("finished_process")
  end
end








