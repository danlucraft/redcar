=====================IMPORTANT NOTE=========================

Redcar is pre-Release, pre-Beta, pre-Alpha. If you try and
use it it will:
  a. Crash. Guaranteed.
  b. Lose your data, if you didn't save.

=============================================================

Redcar
    by Daniel Lucraft
    http://www.RedcarEditor.com/

== DESCRIPTION:
  
A pure Ruby text editor for Gnome. Has syntax highlighting,
snippets, macros and is highly extensible.

== FEATURES
  
* Syntax Highlighting for many languages.
* Extensive snippets.
* Ruby plugins
* _Dynamic_ macros.

== INSTALL:

For now, installation is still a pain. 

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
  $ sudo gem install log4r rails

5. Download the Textmate bundles:
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
