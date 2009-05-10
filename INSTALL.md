
Installing on Ubuntu 9.04 (Jaunty)
==================================

This assumes that you have Ruby installed from packages. It will overwrite your Ruby if you have Ruby installed from source, so be sure.

  0. (Install Ruby from packages, if you haven't already).

    sudo apt-get install ruby ruby1.8-dev rubygems1.8 libhttp-access2-ruby1.8 rubygems1.8 rake
    echo "export PATH=/var/lib/gems/1.8/bin:\$PATH" >> ~/.bashrc
    source . ~/.bashrc

  1. Download the latest Redcar release.

    wget http://cloud.github.com/downloads/danlucraft/redcar/redcar-latest.tar.gz

  2. Now install Ruby-GNOME2 and other system packages. Ubuntu 9.04 has shipped with an out of date Ruby-GNOME2, so you need to add a new package repository to get the latest version

    echo "deb http://franz.hob-bruneck.info/downloads/ jaunty/" >> /etc/apt/sources.list
    sudo apt-get update
    sudo apt-get install ruby-gnome2 build-essential libonig2 libonig-dev libgtk2.0-dev libglib2.0-dev libgee0 libgee-dev libgtksourceview2.0-dev libxul-dev xvfb libdbus-ruby libwebkit-dev libwebkit-1.0-1

  3. There are a few needed development headers:

    wget redcareditor.com/stuff/missing_x64_headers/rbgdkconversions.h
    wget redcareditor.com/stuff/missing_x64_headers/rbgtkconversions.h
    sudo cp rbgdkconversions.h /usr/lib/ruby/1.8/i486-linux/
    sudo cp rbgtkconversions.h /usr/lib/ruby/1.8/i486-linux/

  4. Install the required Ruby gems:

    sudo gem install oniguruma activesupport rspec cucumber hoe open4 zerenity

  5. Unzip Redcar:

    tar xzf redcar-latest.tar.gz

  6. Build Redcar:

    cd redcar/
    rake build

  7. And start Redcar:

    ./bin/redcar --multiple-instance /optional/path/to/my/project

    (the --multiple-instance flag will be unnecessary from version 0.2 onwards.)

The first time Redcar runs it will spend time loading the Textmate Bundles. 
This only happens once.

INSTALL FROM GITHUB CLONE
=========================

There are instructions on how to get Redcar running from a clone of the github source here: http://redcareditor.com/doc/develop.html


