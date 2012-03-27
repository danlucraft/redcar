package com.redcareditor.theme;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Collections;
import java.util.Comparator;

import com.redcareditor.mate.Scope;
import com.redcareditor.mate.ScopeMatcher;
import com.redcareditor.onig.Match;
import com.redcareditor.plist.Dict;
import com.redcareditor.plist.PlistNode;
import com.redcareditor.plist.PlistPropertyLoader;

public class Theme {
	public String author;
	public String name;
	public Map<String, String> globalSettings = new HashMap<String, String>();
	public List<ThemeSetting> settings = new ArrayList<ThemeSetting>();
	public Map<String, ThemeSetting> cachedSettingsForScopes = new HashMap<String, ThemeSetting>();

	private PlistPropertyLoader propertyLoader;
	private boolean isInitialized = false;

	public Theme(Dict dict) {
		propertyLoader = new PlistPropertyLoader(dict, this);
		propertyLoader.loadStringProperty("name");
		propertyLoader.loadStringProperty("author");
		loadSettings(dict);
	}

	private void loadSettings(Dict dict) {
		List<PlistNode<?>> dictSettings = dict.getArray("settings");
		for (PlistNode<?> node : dictSettings) {
			Dict nodeDict = (Dict) node;
			if (!nodeDict.containsElement("scope")) {
				loadGlobalSetting(nodeDict);
			} else {
				settings.add(new ThemeSetting(nodeDict));
			}
		}
	}

	private void loadGlobalSetting(Dict nodeDict) {
		Dict settingsDict = nodeDict.getDictionary("settings");
		for (String key : settingsDict.value.keySet()) {
			globalSettings.put(key, settingsDict.getString(key));
		}
	}

	public void initForUse() {
		if (isInitialized)
			return;
		isInitialized = true;
		// System.out.printf("initializing theme for use: %s\n", name);
		this.cachedSettingsForScopes = new HashMap<String, ThemeSetting>();
		for (ThemeSetting setting : settings) {
			setting.compileScopeMatchers();
		}
	}

	public ThemeSetting settingsForScope(Scope scope, boolean inner, ThemeSetting excludeSetting) {
		String hierarchyNames = scope.hierarchyNames(inner);
		if (isSettingAlreadyCached(hierarchyNames)) {
			return cachedSettingsForScopes.get(hierarchyNames);
		} else {
			ThemeSetting setting = findSetting(hierarchyNames, inner, excludeSetting);
			cachedSettingsForScopes.put(hierarchyNames, setting);
			return setting;
		}
	}

	private boolean isSettingAlreadyCached(String scope) {
		return cachedSettingsForScopes.containsKey(scope);
	}

	public class ThemeSettingComparator implements Comparator {
		String scopeName;
		
		public ThemeSettingComparator(String scopeName) {
			this.scopeName = scopeName;
		}
		
		public int compare(Object o1, Object o2) {
			return ScopeMatcher.compareMatch(scopeName, ((ThemeSetting) o1).thisMatch, ((ThemeSetting) o2).thisMatch);
		}
	}
	
	public ThemeSetting findSetting(String hierarchyNames, boolean inner, ThemeSetting excludeSetting) {
		// collect matching ThemeSettings
		Match m;
		ArrayList<ThemeSetting> matchingThemeSettings = new ArrayList<ThemeSetting>();
		for (ThemeSetting setting : settings) {
			if (setting == excludeSetting && excludeSetting != null) {
			}
			else {
				if ((m = setting.match(hierarchyNames)) != null) {
					setting.thisMatch = m;
					matchingThemeSettings.add(setting);
				}
			}
		}
		
		Collections.sort(matchingThemeSettings, new ThemeSettingComparator(hierarchyNames));
		
		// merge them together into a single ThemeSetting
		ThemeSetting result = new ThemeSetting();
		for (ThemeSetting ts : matchingThemeSettings) {
			ts.thisMatch = null;
			result.merge(ts);
		}
			
		return result;
	}
}





