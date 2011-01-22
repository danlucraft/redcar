
def reset_search_settings(options)
  if options
    options.is_regex    = Redcar::DocumentSearch::QueryOptions::DEFAULT_IS_REGEX
    options.match_case  = Redcar::DocumentSearch::QueryOptions::DEFAULT_MATCH_CASE
    options.wrap_around = Redcar::DocumentSearch::QueryOptions::DEFAULT_WRAP_AROUND
  end
end

Before do
  reset_search_settings(Redcar::DocumentSearch::IncrementalSearchSpeedbar.previous_options)
  reset_search_settings(Redcar::DocumentSearch::FindSpeedbar.previous_options)
end

