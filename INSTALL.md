
Installing
==========

You must have JRuby installed. See jruby.org for instructions.

To get set up, clone the repo from github:

    $ git clone git://github.com/danlucraft/redcar.git

Download and unpack the jar dependencies:

    $ wget http://cloud.github.com/downloads/danlucraft/redcar/redcar_jars-2009-12-11.tar.gz
    $ tar xzf redcar_jars-2009-12-11.tar.gz

Install the required gems:

    $ jruby -S gem install logging

To run Redcar stand in redcar/ and run

    $ jruby bin/redcar
    
or (on OSX):

    $ jruby -J-XstartOnFirstThread bin/redcar

To run all tests (specs and features) with rake, install rspec and cucumber (as JRUBY gems) and run:

    $ jruby -S rake

Problems?
=========

 * Irc at #redcar on irc.freenode.net
 * Mailing list at http://groups.google.com/group/redcar-editor

