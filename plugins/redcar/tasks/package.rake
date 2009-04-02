
desc "Package a Redcar release (NOT WORKING YET)"
task :package => ["package:gtkmateview", "package:rubygtksourceview2", "package:oniguruma"]

RUBYGTKSOURCEVIEW2_TARBALL = "vendor/ruby-gtksourceview2.tar.bz2"
GTKMATEVIEW_TARBALL = "vendor/gtkmateview.tar.gz"
ONIGURUMA_TARBALL = "vendor/onig-5.9.1.tar.gz"

namespace :package do
  task :clean do
    rm_f RUBYGTKSOURCEVIEW2_TARBALL
    rm_f GTKMATEVIEW_TARBALL
    rm_f ONIGURUMA_TARBALL
  end
  
  task :rubygtksourceview2 do
    unless File.exist?(RUBYGTKSOURCEVIEW2_TARBALL)
      execute_and_check "wget http://redcareditor.com/packages/ruby-gtksourceview2.tar.bz2 -O #{RUBYGTKSOURCEVIEW2_TARBALL}"
    end
  end
  
  task :gtkmateview do
    unless File.exist?(GTKMATEVIEW_TARBALL)
      execute_and_check "wget http://github.com/danlucraft/gtkmateview/tarball/master -O #{GTKMATEVIEW_TARBALL}"
    end
  end
  
  task :oniguruma do
    unless File.exist?(ONIGURUMA_TARBALL)
      execute_and_check "wget http://www.geocities.jp/kosako3/oniguruma/archive/onig-5.9.1.tar.gz -O #{ONIGURUMA_TARBALL}"
    end
  end
  
  def clean_git_dir(dir)
    rm_rf(File.join("vendor", dir, ".git"))
    rm_rf(File.join("vendor", dir, ".gitignore"))
  end
  
  def clean_vendor_dir(dir)
    rm_rf(File.join("vendor", dir))
  end
end
