package com.redcareditor.theme;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.redcareditor.mate.ScopeMatcher;
import com.redcareditor.onig.Match;
import com.redcareditor.plist.Dict;
import com.redcareditor.plist.PlistNode;
import com.redcareditor.plist.PlistPropertyLoader;

public class ThemeSetting {
	public String name;
	public String scopeSelector;
	public String background;
	public String foreground;
	public String fontStyle;
    public String marginBackground;
    public String marginForeground;
	
	public List<ScopeMatcher> matchers;
	
	public Match thisMatch;
	
	public ThemeSetting() {}
	
	public ThemeSetting(Dict dict){
		name          = dict.getString("name");
		scopeSelector = dict.getString("scope");
		
		loadSettings(dict);
		compileScopeMatchers();
	}

	private void loadSettings(Dict dict) {
		Dict settingsDict = dict.getDictionary("settings");
		
		background = getSetting(settingsDict, "background");
		foreground = getSetting(settingsDict, "foreground");
		fontStyle  = getSetting(settingsDict, "fontStyle");
	}

	private String getSetting(Dict settingsDict, String settingName) {
		PlistNode node = settingsDict.value.get(settingName);
		return node == null ? null : (String) node.value;
	}

	public void compileScopeMatchers() {
		this.matchers = ScopeMatcher.compile(scopeSelector);
	}

	public Match match(String scope) {
		Match m;
		if (this.matchers == null)
			compileScopeMatchers();
		
		for (ScopeMatcher matcher : this.matchers) {
			if ((m = ScopeMatcher.testMatchRe(matcher.pos_rx, matcher.neg_rxs, scope)) != null)
				return m;
		}
		return null;
	}
	
	// Merge this ThemeSetting with another, higher priority setting.
	public void merge(ThemeSetting other) {
		//System.out.printf("merging %s %s %s with %s %s %s\n",
		//	name, background, foreground,
		//	other.name, other.background, other.foreground);
		if (other.background != null)
			background = other.background;
		if (other.foreground != null)
			foreground = other.foreground;
		if (other.fontStyle != null)
			fontStyle = other.fontStyle;
	}
}

