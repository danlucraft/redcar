Developing Redcar
=================

This assumes that you already have the dependencies from the INSTALL.txt 
instructions installed. If you haven't made Redcar work from that yet, 
do that first.

Setting up your environment
---------------------------

To get started developing Redcar, you will need to retrieve a copy 
of the source. Redcar uses the `git <http://git-scm.org>`_ source
control system. To clone the repository run::

  git clone git://github.com/danlucraft/redcar.git

Once you have the source, retrieve the dependencies::

  cd redcar/
  git submodule init
  git submodule update

And build the project::

  rake build

Developer Documentation
-----------------------

RDoc files built from the source code are available `here <http://redcareditor.com/rdoc/>`_. 
To build these for yourself run::

  rake rdoc:<plugin_name>

Running Specs and Features
--------------------------

Redcar is tested with `RSpec <http://rspec.info>`_ and 
`Cucumber <http://cukes.info>`_ (except that the specs are broken right now).

You will need to have *xvfb* installed to run the features. On Ubuntu there is a
package called *xvfb*. You can then run all the features with::

  rake features

or you can run the features for one plugin with::

  rake features:edit_tab

If you would like more close control over which scenario is run, you can use the
Cucumber script in bin::

  ./bin/cucumber plugins/edit_tab/features/snippets.feature:45






