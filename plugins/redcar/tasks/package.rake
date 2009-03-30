
desc "Package a Redcar release (NOT WORKING YET)"
task :package => ["package:gtkmateview", "package:rubygtksourceview2"]

namespace :package do
  task :rubygtksourceview2 do
    rm_f "vendor/ruby-gtksourceview2.tar.bz2"
    execute_and_check "wget http://redcareditor.com/packages/ruby-gtksourceview2.tar.bz2 -O vendor/ruby-gtksourceview2.tar.bz2"
  end
  
  task :gtkmateview do
    rm_f "vendor/ruby-gtkmateview.tar.gz"
    execute_and_check "wget http://github.com/danlucraft/gtkmateview/tarball/master -O vendor/gtkmateview.tar.gz"
  end
  
  task :oniguruma do
    rm_f "vendor/onig-5.9.1.tar.gz"
    execute_and_check "wget http://www.geocities.jp/kosako3/oniguruma/archive/onig-5.9.1.tar.gz -O vendor/onig-5.9.1.tar.gz"
  end
  
  def clean_git_dir(dir)
    rm_rf(File.join("vendor", dir, ".git"))
    rm_rf(File.join("vendor", dir, ".gitignore"))
  end
  
  def clean_vendor_dir(dir)
    rm_rf(File.join("vendor", dir))
  end
end
