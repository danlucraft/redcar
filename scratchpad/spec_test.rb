
require 'rubygems'
#require 'ruby-debug'

require 'spec'
require 'spec/runner/formatter/base_formatter'

def lookup_example_groups
  cs = []
  lookup_example_groups1(Spec::Example::ExampleGroup, cs)
  cs
end

def lookup_example_groups1(const, cs)
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

def clean_example_groups(groups)
  groups.sort_by{|c| c.to_s.length}.reverse.each do |c|
    Spec::Example::ExampleGroup.send(:remove_const, c.to_s.split("::").last.intern) rescue nil
  end
end

class RubyFormatter < Spec::Runner::Formatter::BaseFormatter
  def initialize
    super(Spec::Runner.options, StringIO.new)
    @pass_count = 0
    @fail_count = 0
  end

  def start(example_count)
    @example_count = example_count
  end

  def example_passed(*args)
    @pass_count += 1
  end

  def example_failed(*args)
    @fail_count += 1
  end

  def inspect
    "<RubyFormatter total:#{@example_count}, passed:#{@pass_count}, failed:#{@fail_count}>"
  end
end

rspec_options = Spec::Runner.options

def rspec_options.formatters
  @o ||= RubyFormatter.new
  [@o]
end

puts " * loading specs...."
require 'rspec_spec'
puts " * done"
p lookup_example_groups
lookup_example_groups.each do |eg|
  eg.run
end
p rspec_options.reporter.dump
p rspec_options.formatters.first

clean_example_groups(lookup_example_groups)

rspec_options.instance_variable_set(:@o, nil)

