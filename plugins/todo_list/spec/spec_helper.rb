$:.push File.expand_path('../../../../lib', __FILE__)
require File.expand_path("../fixtures/settings", __FILE__)

require 'redcar'
Redcar.environment = :test
Redcar.load_unthreaded
