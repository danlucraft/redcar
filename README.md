{Redcar}
========

[http://redcareditor.com/](http://redcareditor.com/)

## DESCRIPTION

A Ruby text editor.

 * written in Ruby from the ground up
 * runs on JRuby (a fast, compatible Ruby implementation)
 * is cross-platform (Linux, Mac OS X, Windows)
 * highly extensible

Some Redcar features:

 * supports Textmate themes and snippets
 * split screen mode
 * syntax checking for many languages
 * built in REPLs for Ruby, Groovy, Clojure and Mirah.

Some (current) limitations:

 * Only supports UTF-8 file encodings (and therefore ASCII)

![alt text](http://redcareditor.com/images/redcar-4-thumb.png "Title")
![alt text](http://redcareditor.com/images/redcar-1-thumb.png "Title")

## INSTALLATION

You must have Java installed [1]. Redcar is easiest to install as a gem. After installing the gem there is one further install step:

    $ sudo gem install redcar
    $ redcar install
    
The install will take a minute or so to complete as it has to download about 15MB of jar files.

[1] Sun Java or OpenJDK work. Gcj is known not to work.

## USAGE

Run 

    $ redcar

## PROBLEMS?

* Irc at #redcar on irc.freenode.net
* Mailing list at http://groups.google.com/group/redcar-editor

## INSTALLING FROM SOURCE

If you want to contribute to Redcar, you can install it from the source code.

If you're running Windows, as a prerequisite, you'll need to install the rubyzip gem:

    $ gem install rubyzip

Download from github, checkout the submodules and install the jars.

    $ git clone git://github.com/redcar/redcar.git
    $ cd redcar
    $ git submodule init
    $ git submodule update
    $ ruby bin/redcar install

To run:

    $ ruby bin/redcar

### Updating a source build

If you are running a source version of Redcar and you have pulled changes from master, then you may have to update your repo:

    $ git submodule update
    $ ruby bin/redcar install

## TESTS

NB. Redcar features are known to work with Cucumber 0.9.2, and known NOT to work with Cucumber < 0.9

To run the tests you need JRuby installed. You also need rspec and cucumber installed as JRuby gems. See jruby.org for this, or install with rvm.

To run all specs and features:

    $ jruby -S bundle install
    $ jruby -S rake

NB. You must leave the test window focussed while the features run. Some of the tests will fail if the test process is in the background.

### Specs

On OSX:

    $ jruby -J-XstartOnFirstThread -S spec plugins/#{plugin_name}/spec/

On Linux:

    $ jruby -S spec plugins/#{plugin_name}/spec/

  
### Features

On OSX:

    $ jruby -J-XstartOnFirstThread bin/cucumber plugins/#{plugin_name}/features

On Linux:

    $ jruby bin/cucumber plugins/#{plugin_name}/features/

## LICENSE

Redcar is copyright 2007-2011 Daniel Lucraft and contributors.
It is licensed under the GPL2. See the included LICENSE file for details.
