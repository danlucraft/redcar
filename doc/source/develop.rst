Developing Redcar
=================

Setting up your environment
---------------------------

To get started developing Redcar, you will need to retrieve a copy 
of the source. Redcar uses the `git <http://git-scm.org>`_ source
control system, and the repositories are::

  git clone git://github.com/danlucraft/redcar.git
  git clone git://github.com/danlucraft/gtkmateview.git
  git clone git://github.com/danlucraft/redcar-bundles.git

Once they have been downloaded, the gtkmateview source must be built, which can be
done with::

  cd gtkmateview/dist
  ruby extconf.rb
  make

You will also need a copy of *ruby-gtksourceview2*, which can be obtained and built
like so::

  wget http://redcareditor.com/packages/ruby-gtksourceview2.tar.bz2
  tar xjf ruby-gtksourceview2.tar.bz2
  cd gtksourceview2
  ruby extconf.rb
  make

You will also need to insert symlinks to the correct locations in the Redcar source
tree. 

* *redcar/textmate* should point to *redcar-bundles*
* *redcar/vendor/gtkmateview* should point to *gtkmateview*
* *redcar/vendor/gtksourceview2* should point to *ruby-gtksourceview2*

Developer Documentation
-----------------------

RDoc files built from the source code are available `here <http://redcareditor.com/rdoc/>`_.

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






