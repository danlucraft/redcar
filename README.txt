Redcar
    by Daniel Lucraft
    http://RedcarEditor.com/

== DESCRIPTION:
  
A pure Ruby text editor for Gnome. Has syntax highlighting,
snippets, macros and is highly extensible.

== FEATURES
  
* Syntax highlighting for many languages.
* Extensive snippets.
* Ruby plugins.

== INSTALL:

For now, installation is still pretty long-winded. It's a bit easier if you live within Ubuntu's packages.

=== Installing on Ubuntu 8.04 - 9.04

1. First you will need to install Ruby-GNOME2, the build tools and some other necessary libraries. On Ubuntu/Debian you may simply do:

  $ sudo apt-get install ruby ruby1.8-dev rubygems1.8 libhttp-access2-ruby1.8 rubygems1.8 ruby-gnome2 build-essential libonig2 libonig-dev libgtk2.0-dev libglib2.0-dev libgee0 libgee-dev libgtksourceview2.0-dev libxul-dev xvfb libdbus-ruby

If you are not using Debian/Ubuntu, or have installed Ruby yourself from source, then you should make sure that you have these libraries installed:
  1. Ruby, Rubygems, Glib, Gtk, GtkSourceView 2 with development headers
  2. Ruby-GNOME2 http://ruby-gnome2.sourceforge.jp/
  3. Oniguruma (any version will probably work, tested with 5.9.0) http://www.geocities.jp/kosako3/oniguruma/
  4. Libgee http://live.gnome.org/Libgee
  5. Ruby DBus git://github.com/sdague/ruby-dbus.git
  6. GtkSourceView 2.0

2. Install the required Ruby gems:

  $ sudo gem install oniguruma activesupport rspec cucumber hoe open4 zerenity

3. Download Redcar:

  $ wget http://redcareditor.com/releases/redcar-latest.tar.gz

4. Unzip the source:

  $ tar xzvf redcar-latest.tar.gz

5. Build Redcar

  $ cd redcar/
  $ rake build

6. Now try running Redcar
  $ cd REDCAR_PATH
  $ ./bin/redcar
 
The first time Redcar runs it will spend time loading the Textmate Bundles. 
This only happens once.

NB. Ubuntu 9.10 users should start Redcar with the --multiple-instance flag, as
there appears to be a bug in the Jaunty ruby dbus package.

== Running Features

rake features
rake features:[plugin_name]

== LICENSE:

Redcar is copyright 2008 Daniel B. Lucraft and contributors. It is licensed under the GPL2. 
See the included LICENSE file for details.
