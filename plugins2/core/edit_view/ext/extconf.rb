# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf-gnome2'

# Give it a name
extension_name = 'redcar_ext'

PKGConfig.have_package('glib-2.0')
PKGConfig.have_package('gtk+-2.0')
PKGConfig.have_package('gtksourceview-1.0')

have_library("onig")

# The destination
dir_config(extension_name)

# Do the work
create_makefile(extension_name)
