
Installing
==========

To get set up, clone the repo from github:

    $ git clone git://github.com/danlucraft/redcar.git

Download the SWT release that is appropriate for your platform from
eclipse.org/swt and put the swt.jar file into

    plugins/application_swt/vendor/swt/{linux,osx64,osx}/

To run Redcar stand in redcar/ and run

    $ jruby bin/redcar

To run all tests (specs and features) with rake (must be JRUBY rake),  
install rspec and cucumber (as JRUBY gems) and run:

    $ rake

Problems?
=========

 * Irc at #redcar on irc.freenode.net
 * Mailing list at http://groups.google.com/group/redcar-editor

