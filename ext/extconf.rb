# this file is invoked when the gem is installed
# rubygems expects it to build a gem, so we need to work around that


require File.join(File.dirname(__FILE__), %w(.. lib redcar install.rb))

# Zerg::Support::Gems.ensure_on_path 'zerg'

# we really shouldn't be abusing rubygems' root; then again, the Debian
# maintainers shouldn't be abusing the patience of Ruby developers

installation = Redcar::Install.new

installation.emulate_extension_install 'redcar_post_install'
installation.grab_jruby
installation.grab_common_jars
installation.grab_platform_dependencies
installation.grab_redcar_jars