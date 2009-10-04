
module Redcar
  module PluginTests
    class HookTest < Test::Unit::TestCase
      def setup
        Hook.unregister("HookTestHook")
        Hook.register("HookTestHook")
        Hook.unregister("HookTestHook2")
        Hook.register("HookTestHook2")
      end
      
      def test_register
        assert Hook.names.include?("HookTestHook")
      end
      
      def test_attach_and_trigger
        @value = nil
        Hook.attach :HookTestHook do
          @value = 34
        end
        assert_equal nil, @value
        Hook.trigger :HookTestHook
        assert_equal 34, @value
      end
      
      def test_attach_and_trigger2
        @value = nil
        Hook.attach :HookTestHook, :HookTestHook2 do
          @value = 34
        end
        assert_equal nil, @value
        Hook.trigger :HookTestHook
        assert_equal 34, @value
        @value = nil
        Hook.trigger :HookTestHook2
        assert_equal 34, @value
      end
      
      def test_clear_my_hooks
        @value = nil
        Hook.attach :HookTestHook, :HookTestHook2 do
          @value = 34
        end
        assert_equal nil, @value
        Hook.clear_my_hooks
        Hook.trigger :HookTestHook
        Hook.trigger :HookTestHook2
        assert_equal nil, @value
      end
      
      def test_clear_plugin_hooks
        @value = nil
        Hook.attach :HookTestHook, :HookTestHook2 do
          @value = 34
        end
        assert_equal nil, @value
        Hook.clear_plugin_hooks(Hook)
        Hook.trigger :HookTestHook
        Hook.trigger :HookTestHook2
        assert_equal nil, @value
      end
      
      def test_will_not_register_duplicate_hook
        assert_raises RuntimeError do
          Hook.register :HookTestHook
        end
      end
      
      def test_will_not_attach_to_unknown_hook
        assert_raises RuntimeError do
          Hook.attach :HookTestNonExistantHook do
            @value = 34
          end
        end
      end
      
      def test_will_not_trigger_unknown_hook
        assert_raises RuntimeError do
          Hook.trigger :HookTestNonExistantHook do
            @value = 34
          end
        end
      end
      
      def test_before_block
        @value = nil
        Hook.attach :before_HookTestHook do 
          @value = 10
        end
        Hook.trigger :HookTestHook do
          @value += 5
        end
        assert_equal 15, @value
      end
      
      def test_after_block
        @value = nil
        Hook.attach :after_HookTestHook do 
          @value += 10
        end
        Hook.trigger :HookTestHook do
          @value = 10
        end
        assert_equal 20, @value
      end
      
      def test_object_passing
        Hook.attach :HookTestHook do |str|
          str.reverse!
        end
        str = "Hello!"
        Hook.trigger :HookTestHook, str
        assert_equal "!olleH", str
      end
      
      def test_multiple_object_passing
        Hook.attach :HookTestHook do |str1, str2|
          str1.replace(str1 + str2)
        end
        str1 = "Hel"
        str2 = "lo!"
        Hook.trigger :HookTestHook, str1, str2
        assert_equal "Hello!", str1
      end
    end
  end
end
