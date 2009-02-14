
module Redcar::Testing
  class TabFormatter < Spec::Runner::Formatter::ProgressBarFormatter
    def initialize
      @tab_output = StringIO.new
      super(Spec::Runner.options, @tab_output)
      @pass_count = 0
      @fail_count = 0
    end

    def start(example_count)
      super
      @example_count = example_count
    end

    def example_passed(*args)
      super
      @pass_count += 1
    end

    def example_failed(*args)
      super
      @fail_count += 1
    end

    def results
      [@example_count, @pass_count, @fail_count, @tab_output.string]
    end
  end
end
