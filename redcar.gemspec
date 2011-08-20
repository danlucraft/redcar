
class RedcarGemspecHelper
  def self.remove_gitignored_files(filelist)
    ignores = File.readlines(".gitignore")
    ignores = ignores.select {|ignore| ignore.chomp.strip != "" and ignore !~ /^#/}
    ignores = ignores.map {|ignore| Regexp.new(ignore.chomp.gsub(".", "\\.").gsub("*", ".*"))}
    r = filelist.select {|fn| not ignores.any? {|ignore| fn =~ ignore }}
    r.select {|fn| fn !~ /\.git/ }
  end
  
  def self.remove_matching_files(list, string)
    list.reject {|entry| entry.include?(string)}
  end

  def self.gem_manifest
    r = %w(CHANGES LICENSE Rakefile README.md) +
                            Dir.glob("bin/redcar") +
                            Dir.glob("config/**/*") +
                            remove_gitignored_files(Dir.glob("lib/**/*")) +
                            remove_gitignored_files(Dir.glob("plugins/**/*"))
    remove_matching_files(r, "multi-byte")
  end
end

Gem::Specification.new do |s|
  s.name        = "redcar-dev"
  s.version     = "0.12.16dev" # also change in lib/redcar.rb
  s.platform    = "java"
  s.authors     = ["Daniel Lucraft"]
  s.email       = ["dan@fluentradical.com"]
  s.homepage    = "http://github.com/danlucraft/redcar"
  s.summary     = "A pure Ruby text editor"
  s.description = ""
 
  s.files        = RedcarGemspecHelper.gem_manifest
  s.executables  = ["redcar"]
  s.require_path = 'lib'
  s.extra_rdoc_files  = %w(README.md LICENSE CHANGES Rakefile)
  
  s.add_dependency("ffi")
  s.add_dependency("git")
  s.add_dependency("json")
  s.add_dependency("spoon")
  s.add_dependency("lucene", "~> 0.5.0.beta.1")
  s.add_dependency("net-ssh")
  s.add_dependency("net-sftp")
  s.add_dependency("net-ftp-list")
  s.add_dependency("jruby-openssl")
  s.add_dependency("ruby-blockcache")
  s.add_dependency("bouncy-castle-java")
  
  s.add_dependency("swt")
  s.add_dependency("plugin_manager")
  s.add_dependency("redcar-icons")
  s.add_dependency("redcar-svnkit")
  s.add_dependency("redcar-bundles")
  s.add_dependency("redcar-javamateview")
  
  s.add_development_dependency("cucumber")
  s.add_development_dependency("rspec")
  s.add_development_dependency("watchr")
end

