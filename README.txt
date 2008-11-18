=====================IMPORTANT NOTE=========================

Redcar is pre-Release, pre-Beta, pre-Alpha. If you try and
use it it will:
  a. Crash. Guaranteed.
  b. Lose your data, if you didn't save.

=============================================================

Redcar
    by Daniel Lucraft
    http://www.RedcarIDE.com/

== DESCRIPTION:
  
A pure Ruby text editor for Gnome. Has syntax highlighting,
snippets, macros and is highly extensible.

== FEATURES
  
* Syntax Highlighting for many languages.
* Extensive snippets.
* Ruby plugins
* _Dynamic_ macros.

== INSTALL:

For now, installation is still pretty long-winded. It's a bit easier if you live within Ubuntu's packages.

=== Installing

1. First you will need to install Ruby-GNOME2, the build tools and some other necessary libraries. On Ubuntu/Debian you may simply do:

  $ sudo apt-get install ruby ruby1.8-dev ruby-gnome2 build-essential libonig2 libonig-dev subversion libgtk2.0-dev libglib2.0-dev libgee0 libgee-dev libgtksourceview2.0-dev 

If you are not using Debian/Ubuntu, or have installed Ruby yourself from source, then you should make sure that you have these libraries installed:
  1. Ruby Rubygems, Glib, Gtk, GtkSourceView 2
  1. Ruby-GNOME2 http://ruby-gnome2.sourceforge.jp/
  2. Oniguruma (any version will probably work, tested with 5.9.0) http://www.geocities.jp/kosako3/oniguruma/
  3. Libgee http://live.gnome.org/Libgee

2. Install the required Ruby gems:

  $ sudo gem install oniguruma activesupport log4r rspec

3. Get the Redcar source.

  $ git clone git://github.com/danlucraft/redcar.git

4. Install the GtkSourceView 2.0 bindings for Ruby-GNOME2:
  $ wget http://www.ruby-forum.com/attachment/2323/ruby-gtksourceview2.tar.bz2
  $ tar xjvf ruby-gtksourceview2.tar.bz2
  $ cd gtksourceview2
  $ ruby extconf.rb
  $ make
  $ sudo make install

5. Checkout the GtkMateView extension:
  $ cd REDCAR_SRC_PATH/plugins2/edit_view/
  $ git clone git://github.com/danlucraft/gtkmateview.git
  $ cd gtkmateview/dist
  $ ruby extconf.rb
  $ make

There will be quite a lot of warnings during this compilation, but there shouldn't be any errors.

6. Download the Textmate bundles:
  $ export LC_CTYPE=en_US.UTF-8
  $ cd /usr/local/share/
  $ sudo svn co http://macromates.com/svn/Bundles/trunk textmate

7. Now try running Redcar
  $ cd REDCAR_PATH
  $ ./bin/redcar

=== Installing from source

1. Please make sure you have an up-to-date version of Ruby-Gnome2 
installed. This can be downloaded from http://ruby-gnome2.sourceforge.jp/, 
or may be packaged for your distribution.

2. Install Oniguruma. 5.9.0 seems to work. It can be downloaded here:
http://www.geocities.jp/kosako3/oniguruma/

3. Install the Ruby gem 'oniguruma'
  $ sudo gem install oniguruma

This must build native extensions correctly for Redcar to function. To test whether
oniguruma is installed correctly open irb and check you get this:

  >> require 'rubygems'; require 'oniguruma'; Oniguruma::ORegexp.new("(?<=foo)bar")
  => /(?<=foo)bar/

4. Install other required gems
  $ sudo gem install log4r rails rspec hoe

5. Download the Textmate bundles. You will need Subversion installed to get them:
  $ export LC_CTYPE=en_US.UTF-8
  $ cd /usr/local/share/
  $ sudo svn co http://macromates.com/svn/Bundles/trunk textmate

6. Checkout the GtkMateView extension:
  $ cd REDCAR_PATH
  $ git clone git://github.com/danlucraft/gtkmateview.git plugins2/edit_view/gtkmateview
  $ cd plugins2/edit_view/gtkmateview/dist
  $ ruby extconf.rb
  $ make

This should complete without errors. Though there will be a ton of warnings.

7. Now try running Redcar
  $ cd REDCAR_PATH
  $ ./bin/redcar

The first time Redcar runs it will spend time loading the Textmate Bundles. 
This only happens once.

== LICENSE:

Redcar is copyright 2008 Daniel B. Lucraft and contributors. It is licensed under the GPL2. 
See the included LICENSE file for details.
