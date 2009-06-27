
Installing on Ubuntu 9.04 (Jaunty)
==================================

This assumes that you have Ruby installed from packages. This will overwrite your Ruby if you have Ruby installed from source, so be sure.

  0. (Install Ruby from packages, if you haven't already).

        sudo apt-get install ruby ruby1.8-dev rubygems1.8 libhttp-access2-ruby1.8 rubygems1.8 rake
        echo "export PATH=/var/lib/gems/1.8/bin:\$PATH" >> ~/.bashrc
        source ~/.bashrc

  1. Now install Ruby-GNOME2 and other system packages. Ubuntu 9.04 has shipped with an out of date Ruby-GNOME2, so you need to add a new package repository to get the latest version. (If you are using a version of Ruby installed from source, you will need to download and install Ruby-GNOME2 from http://ruby-gnome2.sourceforge.jp/ instead of doing this.)

        sudo sh -c 'echo "deb http://franz.hob-bruneck.info/downloads/ jaunty/" >> /etc/apt/sources.list'
        sudo apt-get update
        sudo apt-get install ruby-gnome2 build-essential libonig2 libonig-dev libgtk2.0-dev libglib2.0-dev libgee0 libgee-dev libgtksourceview2.0-dev libxul-dev xvfb libdbus-ruby libwebkit-dev libwebkit-1.0-1

  2. There are a few needed development headers:

        wget redcareditor.com/stuff/missing_x64_headers/rbgdkconversions.h
        wget redcareditor.com/stuff/missing_x64_headers/rbgtkconversions.h
        
     If you are on 32bit Ubuntu (most likely):    
    
        sudo cp rbgdkconversions.h /usr/lib/ruby/1.8/i486-linux/
        sudo cp rbgtkconversions.h /usr/lib/ruby/1.8/i486-linux/
        
     If you are on 64bit Ubuntu
     
        sudo cp rbgdkconversions.h /usr/lib/ruby/1.8/x86_64-linux/
        sudo cp rbgtkconversions.h /usr/lib/ruby/1.8/x86_64-linux/

  3. Install the required Ruby gems:

        sudo gem install oniguruma activesupport rspec cucumber hoe open4 zerenity statemachine

  4. Clone the Redcar source.
  
        git clone git://github.com/danlucraft/redcar.git
  
    (You can install git on Ubuntu with "sudo apt-get install git-core")

  5. Checkout the latest Redcar release.
  
        git checkout stable

  5. Download the Redcar git submodules

        cd redcar/
        git submodule init
        git submodule update

  6. Build Redcar
  
        rake build

  7. And start Redcar:

        ./bin/redcar /optional/path/to/my/project

The first time Redcar runs it will spend time loading the Textmate Bundles. 
This only happens once.

Problems?
=========

 * Irc at #redcar on irc.freenode.net
 * Mailing list at http://groups.google.com/group/redcar-editor

