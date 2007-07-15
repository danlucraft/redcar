
require 'rubygems'
require 'hoe'
require './lib/redcar.rb'

Hoe.new('Redcar', Redcar::VERSION) do |p|
  p.rubyforge_name = 'redcar'
  p.author = 'Daniel Lucraft'
  p.email = 'dan@fluentradical.com'
  p.summary = 'Pure Ruby text editor.'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
end

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
