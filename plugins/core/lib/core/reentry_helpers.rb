module Redcar
  module ReentryHelpers
    def ignore_changes
      @ignore_changes ||= Hash.new(0)
    end
    
    def ignore(name)
      ignore_changes[name] += 1
      yield if ignore_changes[name] == 1
      ignore_changes[name] -= 1
    end
  end
end