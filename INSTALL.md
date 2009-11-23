
Installing
==========

You must have JRuby installed. JRuby version 1.4.0 appears to have some Java interop regressions so you must get at least revision 1022103f1df259428d479baa5cbdb529b4490d3f from 22 Nov. Refer to jruby.org for instructions on cloning the latest master.

To get set up, clone the repo from github:

    $ git clone git://github.com/danlucraft/redcar.git
    $ git submodule init
    $ git submodule update

Download the SWT release that is appropriate for your platform from
eclipse.org/swt and put the swt.jar file into

    plugins/application_swt/vendor/swt/{linux,osx64,osx}/
    
and into 

    vendor/java-mateview/lib/{linux,osx64,osx}

Build the jar (you will need ant):

    $ rake build

Install the required gems:

    $ sudo gem install logging

To run Redcar stand in redcar/ and run

    $ jruby bin/redcar

To run all tests (specs and features) with rake (must be JRUBY rake),  
install rspec and cucumber (as JRUBY gems) and run:

    $ rake

Problems?
=========

 * Irc at #redcar on irc.freenode.net
 * Mailing list at http://groups.google.com/group/redcar-editor

