#!/usr/bin/env ruby

namespace :test do
  task :all => [:syntax]
  
  task :syntax do
    sh "testrb test/syntax_texttab_test.rb"
    sh "rg test/syntax_grammar_test.rb"
    sh "rg test/syntax_scope_test.rb"
    sh "rg test/syntax_parser_test.rb"
    sh "rg test/syntax_theme_test.rb"
  end

  task :syntax_quick do
    sh "rg test/syntax_grammar_test.rb"
    sh "rg test/syntax_scope_test.rb"
    sh "rg test/syntax_parser_test.rb"
    sh "rg test/syntax_theme_test.rb"
  end
end

# require "rake" 
# require "rake/testtask" 

# task :default => [:test]

# Rake::TestTask.new do |test|
#   test.libs << "test" 
#   test.test_files = Dir[ "test/test_*.rb" ]
#   test.verbose = true
# end