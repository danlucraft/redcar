
module Redcar::Tests
  class TemplateTest < Test::Unit::TestCase
    def setup
      @buf = Redcar::Document.new
    end
    
    def test_loaded_templates
      assert !Redcar::Template.templates.empty?
    end
    
    def test_insert_simple_template
      Redcar::Template.insert_template("Demetrius", @buf)
      assert_equal "Demetrius", @buf.text
    end
  end
end
