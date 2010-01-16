$:.push File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')
require 'redcar'
Redcar.boot
Redcar.load
Dir[File.dirname(__FILE__) + "/application/controllers/*.rb"].each do |fn|
  require fn
end
  
