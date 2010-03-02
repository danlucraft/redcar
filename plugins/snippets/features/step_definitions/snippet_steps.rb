Given /^there is a snippet with tab trigger "([^\"]*)" and scope "([^\"]*)" and content$/ do |tab, scope, string|
  content = unescape_text(string[2..-1])
  snippet = Redcar::Snippets::Snippet.new(nil, content, :tab => tab, :scope => scope)
  p [:adding, snippet]
  Redcar::Snippets.registry.snippets << snippet
  remove_snippet_after(snippet)
end

def remove_snippet_after(snippet)
  (@snippets_to_remove ||= []) << snippet
end

After do
  @snippets_to_remove.each do |snippet|
    Redcar::Snippets.registry.remove(snippet)
  end
end