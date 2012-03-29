require 'rake/clean'
require 'net/http'

jruby_command = case Config::CONFIG["host_os"]
  when /darwin/i
    'jruby -J-XstartOnFirstThread '
  else
    'jruby '
end

task :default => 'jruby:test'

namespace :java do
  desc "Rebuild the java class files"
  task :compile do
    puts "Compiling java files to *.class files"
    sh %+ant compile+
  end
  
  desc "Run jUnit tests against freshly compiled java classes"
  task :test do
    puts "Running JUnit Tets"
    sh %+ant test+
  end
  
  desc "Run Benchmarks"
  task :benchmark do
    puts "Compiling java files to *.class files"
    sh %+ant compile-bench+
    runner = 'ch.mollusca.benchmarking.BenchmarkRunner'
    classes = ['com.redcareditor.mate.GrammarBenchmark']
    classpath = '.:bench/:bin/:lib/joni.jar:lib/jdom.jar:lib/jcodings.jar'
    classes.each do |clazz|
      sh "java -cp #{classpath} #{runner} #{clazz}"
    end
  end
end

namespace :jruby do
  desc "Run ruby tests against a freshly compiled build"
  task :test => ['java:test'] do
    puts "Running RSpec Tests"
    sh %+#{jruby_command} -S spec spec/+
  end
end


namespace :build do
  desc "Fetch the swt jars from the gem"
  task :prepare do
    require 'rubygems'
    require 'java'
    gem 'swt'
    require 'swt/jar_loader'
    swt_jar_dir = File.dirname(Swt.jar_path)
    
    mkdir_p File.expand_path("../lib/swt_jars", __FILE__)
    %w(linux32 linux64 osx32 osx64 win32 win64).each do |platform|
      dir = File.expand_path("../lib/swt_jars/#{platform}", __FILE__)
      mkdir_p dir
      from = swt_jar_dir + "/swt-#{platform}.jar"
      to   = dir + "/swt.jar"
      cp from, to
    end
  
    mkdir_p File.expand_path("../lib/jface_jars", __FILE__)
    
    p swt_jar_dir
    p Dir[swt_jar_dir + "/../jface/org.ecl*.jar"]
    Dir[swt_jar_dir + "/../jface/org.ecl*.jar"].each do |from, to|
      to = File.expand_path("../lib/jface_jars/#{File.basename(from)}", __FILE__)
      cp from, to
    end
  end
  
  desc "Get jruby-complete to build release jar"
  task :get_jruby do
    jruby_complete = "jruby-complete-#{JRUBY_VERSION}.jar"
    location = "http://dist.codehaus.org/jruby/#{JRUBY_VERSION}/#{jruby_complete}"
    local_path = "lib/#{jruby_complete}"
    unless File.exists?(local_path)
      puts "Getting required #{jruby_complete}"
      response = Net::HTTP.get(URI.parse(location))
      File.open(local_path, "wb") { |file| file.write(response) }
    else
      puts "Already have required #{jruby_complete}, skipping download"
    end
  end
  
  # desc "Build the release *.jar"
  # task :release => [:get_jruby] do
  #   puts "Building release *.jar"
  #   
  # end
end