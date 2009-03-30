
desc "Build bundled dependencies (NOT WORKING YET)"
task :build => ["build:gtksourceview2", "build:gtkmateview"]

namespace :build do
  task :gtkmateview do
    puts "Building gtkmateview"
    execute_and_check "tar xzvf vendor/gtkmateview.tar.gz -C vendor/"
    dir = Dir[File.join(%w[vendor danlucraft-gtkmateview*])].first
    mv(dir, File.join(%w[vendor gtkmateview]))
    cd(File.join(*%w[vendor gtkmateview dist])) do
      execute_and_check "ruby extconf.rb"
      execute_and_check "make"
    end
  end
  
  task :gtksourceview2 do
    puts "Building gtksourceview2"
    cd(File.join(*%w[vendor gtksourceview2])) do
      execute_and_check "ruby extconf.rb"
      execute_and_check "make"
    end
  end
  
  task :oniguruma do
    puts "Building oniguruma"
  end
end
