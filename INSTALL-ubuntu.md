
Installing
==========
These has been tested on in the following env:
karmic koala (9.10) beta 
sun jdk6 u15 (from the ubuntu repositories)
jruby 1.4.0RC2 (binary) from jruby.org
swt 3.5.1 from eclipse.org/swt

To get set up, clone the repo from github:

    $ git clone git://github.com/danlucraft/redcar.git
    $ git submodule init
    $ git submodule update

Download jruby 1.4.0RC2 from jruby and unpack it on /opt as root.
And create the a symlink:
cd /opt
ln -s jruby-1.4.0RC2 jruby
Then append the following at the end of your ~/.profile
PATH=$PATH:/opt/jruby/bin:~/.gem/jruby/1.8/bin

Download the SWT release that is appropriate for your platform from
eclipse.org/swt and put the swt.jar file into

    plugins/application_swt/vendor/swt/{linux,osx64,osx}/
    
and into 

    vendor/java-mateview/lib/{linux,osx64,osx}

Download the jruby binary from jruby.org 

Build the jar (you will need ant):

    $ rake build

To run Redcar stand in redcar/ and run

    $ jruby bin/redcar

To run all tests (specs and features) with rake (must be JRUBY rake),  
install rspec and cucumber (as JRUBY gems) 
jruby -S gem install cucumber
jruby -S gem install rspec

and run:

    $ rake

Problems?
=========

 * Irc at #redcar on irc.freenode.net
 * Mailing list at http://groups.google.com/group/redcar-editor

