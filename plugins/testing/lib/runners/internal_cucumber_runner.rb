
module Redcar::Testing
  class InternalCucumberRunner
    class << self
      attr_accessor :in_cucumber_process
      attr_accessor :ready_for_cucumber
    end
  end
end
