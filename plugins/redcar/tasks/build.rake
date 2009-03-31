
desc "Build bundled dependencies (NOT WORKING YET)"
task :build => [
  # "build:gtksourceview2", 
  # "build:gtkmateview", 
  "build:gtk",
  "build:libs",
  "build:rubygnome2",
  "build:check_gems"
]

def check_header(name)
  (Dir["/usr/include/#{name}"] + Dir["/usr/local/include/#{name}"]).any?
end

def check_so(name)
  (Dir["/usr/lib/#{name}"] + Dir["/usr/local/lib/#{name}"]).any?
end

def found(name, opts={})
  cputs("#{name.ljust(30, ".")} found", [GREEN_FG, GREY_BG], opts)
end

def missing(name, opts={})
  cputs("#{name.ljust(30, ".")} not found", [RED_FG, GREY_BG], opts)
end

namespace :build do
  task :rubygnome2 do
    begin
      require 'gtk2'
      found("Ruby-GNOME2")
    rescue LoadError
      missing("Ruby-GNOME2")
    end
    begin
      require 'gtksourceview2'
      found("ruby-gtksourceview2")
    rescue LoadError
      missing("ruby-gtksourceview2")
    end
  end
  
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
  
  task :libs do
    cputs("Libraries", GREEN_FG)
    [
      ["onig*", "*libonig*", "Oniguruma"],
      ["gtkmateview*", "libgtkmateview*", "gtkmateview"]
    ].each do |header, so, name|
      if (!header or check_header(header)) and 
          (!so or check_so(so))
        found(name)
      else
        missing(name)
      end
    end
  end
  
  task :gtk do
    cputs("GTK", [GREEN_FG], :no_newline => true)
    %w[glib gtk+-2.0 gtksourceview-2.0 xulrunner-gtkmozembed].each do |pkg|
      if execute("pkg-config --exists #{pkg}")
        found(pkg, :no_newline => true)
      else
        missing(pkg, :no_newline => true)
      end
    end
    puts
    puts
  end
  
  task :check_gems do
    cputs("\nRubygems", GREEN_FG)
    %w(oniguruma cucumber zerenity).each do |gem|
      begin
        require gem
        found(gem)
      rescue LoadError
        missing(gem)
      end
    end
  end
end




