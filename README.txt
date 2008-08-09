=====================IMPORTANT NOTE=========================

Redcar is pre-Release, pre-Beta, pre-Alpha. If you try and
use it it will:
  a. Crash. Guaranteed.
  b. Lose your data, if you didn't save.
  c. Almost certainly not work on your machine anyway,
    because the dependencies are incredible and 
    undocumented and there are undocumented extensions that 
    need compiling.

=============================================================

Redcar
    by Daniel Lucraft
    http://www.RedcarEditor.com/

== DESCRIPTION:
  
A pure Ruby text editor for Gnome. Has syntax highlighting,
snippets, macros and is highly extensible.

== FEATURES
  
* Syntax Highlighting.
* Snippets.
* Macros.
* _Dynamic_ macros.
* Can edit menu layout and definitions on the fly.
* Can script new Ruby commands on the fly.

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

4. Download the Textmate bundles:
  $ export LC_CTYPE=en_US.UTF-8
  $ cd REDCAR_PATH
  $ svn co http://macromates.com/svn/Bundles/trunk textmate

5. Compile the Redcar native extension:
  $ cd REDCAR_PATH
  $ cd plugins2/core/edit_view/ext
  $ ruby extconf.rb
  $ make

This should complete without errors. Though there will be a ton of warnings.

6. Now try running Redcar
  $ ./bin/redcar

The first time Redcar runs it will spend time loading the Textmate Bundles and Themes. 
This only happens once.

== LICENSE:

(The MIT License)

Copyright (c) 2007 Daniel Lucraft

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
