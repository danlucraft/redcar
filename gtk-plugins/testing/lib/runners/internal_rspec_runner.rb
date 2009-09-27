
module Redcar::Testing
  class InternalRSpecRunner
    def self.spec_all_plugins
      ARGV.clear
      set_redcar_formatter
      puts "speccing all plugins"
      bus("/plugins").children.each do |slot|
        load_plugin_files(slot.name)
      end
      lookup_example_groups.each do |eg|
        eg.run(Spec::Runner.options)
      end
      output_results
      cleanup_rspec
    end
    
    def self.spec_plugin(plugin_name)
      set_redcar_formatter
      puts "speccing plugin name: #{plugin_name}"
      load_plugin_files(plugin_name)
      
      lookup_example_groups.each do |eg|
        eg.run(Spec::Runner.options)
      end
      
      output_results
      
      cleanup_rspec
    end
    
    def self.output_results
      tab = Redcar.win.new_tab(Redcar::TestViewTab)
      tab.title = "RSpec Results"
      results = prepare_results
      puts results
      tab.document.text = results
      tab.modified = false
      tab.focus
    end
    
    def self.load_plugin_files(plugin_name)
      puts "loading files for #{plugin_name}"
      unless File.exists?(Redcar.PLUGINS_PATH + "/#{plugin_name}/spec")
        puts "   no specs"
        return
      end
      
      i = 0
      spec_files(plugin_name).each do |spec_file|
        i += 1
        load spec_file
      end
      puts "#{i} files"
    end

    def self.plugin_dir(plugin_name)
      plugin_slot = bus['/plugins/'+plugin_name]
      plugin_slot.data.plugin_configuration.full_base_path + "/"
    end

    def self.spec_files(plugin_name)
      spec_path = "#{plugin_dir(plugin_name)}/spec"
      Dir["#{spec_path}/**/*_spec.rb"]
    end

    def self.lookup_example_groups
      cs = []
      lookup_example_groups1(Spec::Example::ExampleGroup, cs)
      lookup_example_groups1(Test::Unit::TestCase, cs)
      cs
    end

    def self.lookup_example_groups1(const, cs)
      const.constants.sort.each do |c|
        if c =~ /Subclass_/
          subconst = const.const_get(c)
          if !cs.include?(subconst) and const != subconst
            cs << subconst
            lookup_example_groups1(subconst, cs)
          end
        end
      end
      cs
    end
    
    def self.set_redcar_formatter
      rspec_options = Spec::Runner.options
      rspec_options.instance_variable_set(:"@examples", [])
      rspec_options.instance_variable_set(:"@examples_run", true)
      rspec_options.instance_variable_set(:"@argv", [])
      def rspec_options.formatters
        @redcar_formatter ||= Redcar::Testing::TabFormatter.new
        [@redcar_formatter]
      end
    end

    def self.prepare_results
      Spec::Runner.options.reporter.dump
      results = Spec::Runner.options.formatters.first.results
      text=<<-END
     
#{results[3]}
END
    end

    def self.clean_example_groups(groups)
      groups.sort_by{|c| c.to_s.length}.reverse.each do |c|
        if c.to_s =~ /Spec::Example::ExampleGroup/
          Spec::Example::ExampleGroup.send(:remove_const, c.to_s.split("::").last.intern) rescue nil
        elsif c.to_s =~ /Test::Unit::TestCase/
          Test::Unit::TestCase.send(:remove_const, c.to_s.split("::").last.intern) rescue nil
        end
      end
    end

    def self.cleanup_rspec
      clean_example_groups(lookup_example_groups)
      Spec::Runner.options.reporter.send(:clear)
      Spec::Runner.options.instance_variable_set(:@redcar_formatter, nil)
    end
  end
end
