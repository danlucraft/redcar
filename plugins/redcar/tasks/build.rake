
require 'open3'

desc "build redcar"
task :build => [
  "build:dependencies",
  "build:gtksourceview2", 
  "build:gtkmateview",
  "build:rbwebkitgtk"
]

def check_header(name)
  (Dir["/usr/include/#{name}"] + Dir["/usr/local/include/#{name}"]).any?
end

def check_so(name)
  (Dir["/usr/lib/#{name}"] + Dir["/usr/local/lib/#{name}"]).any?
end

def found(name, opts={})
  cputs("#{name.ljust(30, ".")} found", [GREEN_FG], opts)
end

def warning(string)
  cputs("WARNING:\n" + string, [BLUE_FG])
  if ENV["IGNORE_WARNINGS"]
    puts "Ignoring warning. Naughty!\n\n"
  else
    exit(1)
  end
end

def missing(name, suggestion=nil, opts={})
  cputs("#{name.ljust(30, ".")} not found", [RED_FG], opts)
  puts
  if suggestion
    suggestion.split("\n").each do |line|
      line = line.ljust(60)
      if line =~ /\s*\$/
        cputs(line, [BLUE_FG], opts)
      else
        cputs(line, [], opts)
      end
    end
  end
  exit(1)
end

namespace :build do  
  desc "check for necessary dependencies"
  task :dependencies do
    stdin, stdout, stderr = Open3.popen3("ruby -e \"require 'rbconfig'; puts Config::CONFIG['sitedir']\" ")
    stdin.close
    output = stdout.read
    
    ruby_sitedir = output.chomp
    rake_sitedir = Config::CONFIG["sitedir"]
    
    if ruby_sitedir != rake_sitedir
      cputs(<<-WARNING, [RED_FG])
ERROR:
   Your 'rake' executable is running with a different Ruby than your 
   'ruby' executable. 
      
      sitedir for rake: #{rake_sitedir}
      sitedir for ruby: #{ruby_sitedir}
      
   This is likely to have happened if you tried installing Ruby from 
   source and from packages simultaneously.
   WARNING
      exit(1)
    end
    
    cputs("Libraries", [GREEN_FG], :no_newline => true)
    [["glib-2.0", <<TXT],
  Can't find glib development headers.
  On Ubuntu you can install them like this:
  
    $ sudo apt-get install libglib2.0-dev
TXT
     ["gtksourceview-2.0", <<TXT],
  Can't find gtksourceview2 or gtksourceview2 development
  headers. On Ubuntu install them like this:
  
    $ sudo apt-get install libgtksourceview2.0-0 libgtksourceview2.0-dev
TXT
   ].each do |pkg, suggestion|
      if execute("pkg-config --exists #{pkg}")
        found(pkg, :no_newline => true)
      else
        missing(pkg, suggestion)
      end
    end
    puts
    [
      ["onig*", "*libonig*", "Oniguruma", <<TXT
  On Ubuntu you can install Oniguruma like this:              
                                                              
     $ sudo aptitude install libonig2 libonig-dev             
                                                              
TXT
      ],
      ["gee*", "libgee*", "Libgee", <<TXT
  On Ubuntu you can install Libgee like this:
  
     $ sudo apt-get install libgee0 libgee-dev
TXT
      ]
    ].each do |header, so, name, suggestion|
      if (!header or check_header(header)) and 
        (!so or check_so(so))
        found(name)
      else
        missing(name, suggestion)
      end
    end
    
    begin
      require 'gtk2'
    rescue LoadError
      missing("Ruby-GNOME2")
    end

    begin
      require 'dbus'
      found("ruby-dbus")
    rescue LoadError
      missing("ruby-dbus")
    end

    gems = %w(oniguruma cucumber zerenity)
    cputs("\nRubyGems", GREEN_FG)
    gems.each do |gem|
      begin
        require gem
        found(gem)
      rescue LoadError
        missing(gem)
        puts
        cputs "Can't find the RubyGem #{gem}. Try installing:", [GREY_BG]
        cputs "   sudo gem install #{gems.join(" ")}", [GREY_BG, BLUE_FG]
        puts
      end
    end
  end
  
  task :gtkmateview do
    puts "Building gtkmateview"
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
  
  task :rbwebkitgtk do
    puts "Building rbwebkitgtk"
    cd(File.join(*%w[vendor rbwebkitgtk])) do
      execute_and_check "ruby extconf.rb"
      execute_and_check "make"
    end
  end
end




