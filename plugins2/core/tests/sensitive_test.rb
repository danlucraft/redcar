
module Redcar::Tests
  class SensitiveTest < Test::Unit::TestCase
    class SensitiveObject
      class << self
        include Redcar::Sensitive
      end
    end
    
    # example is if there are any open tabs
    Redcar::Sensitive.register(:test_sensitivity, [:new_tab, :close_tab]) do
      win.tabs.length > 0
    end
    
    def teardown
      Redcar::Sensitive.desensitize(SensitiveObject)
    end
    
    def test_active_true_by_default
      assert SensitiveObject.active?
    end
    
    def test_register_sensitivity
      win.tabs.each &:close
      Redcar::Sensitive.sensitize(SensitiveObject, :test_sensitivity)
      assert !SensitiveObject.active?
    end
    
    def test_sensitize_activates
      win.tabs.each &:close
      Redcar::Sensitive.sensitize(SensitiveObject, :test_sensitivity)
      assert !SensitiveObject.active?
      win.new_tab(Redcar::Tab, Gtk::Label.new("foo"))
      assert SensitiveObject.active?
    end
    
    def test_sensitize_deactivates
      win.tabs.each &:close
      Redcar::Sensitive.sensitize(SensitiveObject, :test_sensitivity)
      win.new_tab(Redcar::Tab, Gtk::Label.new("foo"))
      assert SensitiveObject.active?
      win.tabs.each &:close
      assert !SensitiveObject.active?
    end
  end
end
