=begin
extconf.rb for Ruby/GtkSourceView2 extension library
=end

PACKAGE_NAME = "gtksourceview2"
PACKAGE_ID   = "gtksourceview-2.0"

TOPDIR = File.expand_path(File.dirname(__FILE__) + '/..')
MKMF_GNOME2_DIR = TOPDIR + '/glib/src/lib'
SRCDIR = TOPDIR + '/gtksourceview2/src'

$LOAD_PATH.unshift MKMF_GNOME2_DIR
require 'mkmf-gnome2'

PKGConfig.have_package(PACKAGE_ID) or exit 1
setup_win32(PACKAGE_NAME)

add_depend_package("glib2", "glib/src", TOPDIR)
add_depend_package("gtk2", "gtk/src", TOPDIR)

make_version_header("GTKSOURCEVIEW2", PACKAGE_ID)

create_makefile_at_srcdir(PACKAGE_NAME, SRCDIR, "-DRUBY_GTKSOURCEVIEW2_COMPILATION")

create_top_makefile

