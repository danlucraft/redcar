

$menunum -= 5000
require File.dirname(__FILE__) + '/file'
require File.dirname(__FILE__) + '/edit'
require File.dirname(__FILE__) + '/text'
require File.dirname(__FILE__) + '/options'
require File.dirname(__FILE__) + '/toolbar'
$menunum += 5000

module Redcar::Plugins::CoreMenus
  extend FreeBASE::StandardPlugin
end
