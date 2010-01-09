$:.push File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')

require 'redcar'
Redcar.boot
Redcar.require_files
