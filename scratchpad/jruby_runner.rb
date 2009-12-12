# nabbed from Ruby processing thanks!

# Trade in this Ruby instance for a JRuby instance, loading in a 
# starter script and passing it some arguments.
# If --jruby is passed, use the installed version of jruby, instead of 
# our vendored jarred one (useful for gems).
def spin_up(starter_script, sketch, args)
  runner = "#{RP5_ROOT}/lib/ruby-processing/runners/#{starter_script}"
  java_args = discover_java_args(sketch)
  command = @options.jruby ? 
            "jruby #{java_args} \"#{runner}\" #{sketch} #{args.join(' ')}" : 
            "java #{java_args} -cp \"#{jruby_complete}\" org.jruby.Main \"#{runner}\" #{sketch} #{args.join(' ')}"
  exec(command)
  # exec replaces the Ruby process with the JRuby one.
end