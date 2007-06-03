# KeywordProcessor
# This is apparently by someone called Gavin Sinclair, according to the Ruby
# Cookbook, but I can't find it anywhere else.

###
# This mix-in module lets methods match a caller's hash of keyword
# parameters against a hash the method keeps, mapping keyword
# arguments to default parameter values.
#
# If the caller leaves out a keyword parameter whose default value is
# :MANDATORY (a constant in this module), then an error is raised.
#
# If the caller provides keyword parameters which have no
# corresponding keyword arguments, an error is raised.
#
module KeywordProcessor
  MANDATORY = :MANDATORY
  def process_params(params, defaults)
    # Reject params not present in defaults.
    params.keys.each do |key|
      unless defaults.has_key? key
        raise ArgumentError, "No such keyword argument: #{key}"
      end
    end
    result = defaults.dup.update(params)
    # Ensure mandatory params are given.
    unfilled = result.select { |k,v| v == MANDATORY }.map { |k,v| k.inspect }
    unless unfilled.empty?
      msg = "Mandatory keyword parameter(s) not given: #{unfilled.join(', ')}"
      raise ArgumentError, msg
    end
    return result
  end
end

class Object
  include KeywordProcessor
end
