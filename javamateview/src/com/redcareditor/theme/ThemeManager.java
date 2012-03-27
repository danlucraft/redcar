package com.redcareditor.theme;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import com.redcareditor.plist.Dict;

public class ThemeManager {
	public static List<Theme> themes;

	public static List<String> themeNames(String textmateDir) {
		List<String> names = new ArrayList<String>();
		File dir = new File(textmateDir + "/Themes");
		if (dir.exists()) {
			for (String name : dir.list()) {
				if (name.endsWith(".tmTheme")) {
					names.add(name);
				}
			}
		}
		return names;
	}
	
	public static void loadThemes(String textmateDir) {
		if (themes == null) {
    		themes = new ArrayList<Theme>();
		}
        for (String themeName : themeNames(textmateDir)) {
			Dict dict = Dict.parseFile(textmateDir + "/Themes/" + themeName);
			if (dict != null) {
				Theme theme = new Theme(dict);
				themes.add(theme);
			}
		}
	}

	private static boolean initialized() {
		return themes != null;
	}
}
