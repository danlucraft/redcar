Given /^there is a snippet with tab trigger "([^\"]*)" and scope "([^\"]*)" and content$/ do |tab, scope, string|
  snippet = Redcar::Snippets::Snippet.new(nil, string[2..-1], :tab => tab, :scope => scope)
  Redcar::Snippets.registry.snippets << snippet
end
