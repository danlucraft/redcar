require 'fileutils'

require 'cucumber/rake/task'

Dir[File.expand_path("../lib/tasks/*.rake", __FILE__)].each { |f| load f }

if RUBY_PLATFORM =~ /mswin|mingw/
  begin
    # not available for jruby yet
    require 'win32console'
  rescue LoadError
    ARGV << "--nocolour"
  end
end

### GETTING STARTED IN DEVELOPMENT

desc "Prepare code base for development"
task :initialise do
  sh "git submodule update --init --recursive"
end

task :initialize => :initialise

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








