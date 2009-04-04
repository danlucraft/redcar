
desc "Package a Redcar release (set env REDCAR_VERSION to version)"
task :package => [
    "package:gtkmateview", 
    "package:rubygtksourceview2", 
    "package:bundles",
    "package:valar"
  ] do
  mkdir("pkg") rescue nil
  FileUtils.rm_rf(File.join("pkg", "redcar"))
  mkdir(File.join("pkg", "redcar")) rescue nil
  excludes = %w[.git cache pkg]
  contents = Dir["*"] - excludes
  contents.each do |fn|
    cp_r(fn, File.join("pkg", "redcar"))
  end
  cd "pkg" do
    t = "tar czf redcar-#{ENV["REDCAR_VERSION"]}.tar.gz redcar "
    puts t
    execute_and_check t
  end
end

RUBY_SOURCEVIEW = {
  :source => "http://redcareditor.com/packages/ruby-gtksourceview2.tar.bz2",
  :target => "vendor/ruby-gtksourceview2.tar.bz2"
}

namespace :package do
  task :clean do
    rm_f RUBY_SOURCEVIEW[:target]
    rm_f GTKMATEVIEW_TARBALL
    # rm_f ONIGURUMA_TARBALL
  end
  
  task :rubygtksourceview2 do
    unless File.exist?(File.join(%w[vendor gtksourceview2]))
      execute_and_check "wget #{RUBY_SOURCEVIEW[:source]} -O #{RUBY_SOURCEVIEW[:target]}"
      execute_and_check "tar xjf #{RUBY_SOURCEVIEW[:target]} -C vendor/"
      rm(RUBY_SOURCEVIEW[:target])
    end
  end
  
  def rename_globbed_dir(prefix, newdir)
    dir = Dir[prefix].first
    mv(dir, File.join(newdir))
  end

  GTKMATEVIEW_TARBALL = "vendor/gtkmateview.tar.gz"
  task :gtkmateview do
    unless File.exist?(File.join(%w[vendor gtkmateview]))
      execute_and_check "wget http://github.com/danlucraft/gtkmateview/tarball/master -O #{GTKMATEVIEW_TARBALL}"
      execute_and_check "tar xzf #{GTKMATEVIEW_TARBALL} -C vendor/"
      rename_globbed_dir("vendor/danlucraft-gtkmateview*", "vendor/gtkmateview")
      rm(GTKMATEVIEW_TARBALL)
    end
  end
  
  task :bundles do
    unless File.exist?("textmate")
      execute_and_check "wget http://github.com/danlucraft/redcar-bundles/tarball/master -O bundles.tar.gz"
      execute_and_check "tar xzf bundles.tar.gz"
      rename_globbed_dir("danlucraft-redcar-bundles*", "textmate")
      rm("bundles.tar.gz")
    end
  end
  
  task :valar do
    unless File.exist?(File.join(%w[vendor valar]))
      execute_and_check "wget http://github.com/danlucraft/valar/tarball/master -O vendor/valar.tar.gz"
      execute_and_check "tar xzf vendor/valar.tar.gz -C vendor/"
      rename_globbed_dir("vendor/danlucraft-valar*", "vendor/valar")
      rm("vendor/valar.tar.gz")
    end
  end
  
  desc "remove project dependencies"
  task :clean do
   	rm_rf "vendor/gtksourceview2"
	  	rm_rf "vendor/gtkmateview"
    rm_rf "textmate"
    rm_rf "pkg"
    rm_rf "vendor/valar"
  end
  
  def clean_git_dir(dir)
    rm_rf(File.join("vendor", dir, ".git"))
    rm_rf(File.join("vendor", dir, ".gitignore"))
  end
  
  def clean_vendor_dir(dir)
    rm_rf(File.join("vendor", dir))
  end
end
