
$:.push File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')
require 'redcar'
Redcar.environment = :test
Redcar.no_gui_mode!
Redcar.load_unthreaded
