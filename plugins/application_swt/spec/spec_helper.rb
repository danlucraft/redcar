$:.push File.join(File.dirname(__FILE__), '..', '..', '..', 'lib')

require 'redcar'
Redcar.environment = :test
Redcar.load

Spec::Runner.configure do |config|
  config.before(:suite) do
  end

  config.before(:each) do
  end

  config.after(:each) do
  end

  config.after(:suite) do
  end
end

