package com.redcareditor.theme;

import java.util.ArrayList;
import java.util.List;

import com.redcareditor.onig.Rx;

public class ScopeSelector {
	public Rx positiveRegex;
	public List<Rx> negativeRegexes;

	public static List<ScopeSelector> compile(String scopeSelector) {
		List<ScopeSelector> result = new ArrayList<ScopeSelector>();
		for (String selector : scopeSelector.split(",")) {
			result.add(new ScopeSelector(selector));
		}
		return result;
	}

	private ScopeSelector(String selector) {
		negativeRegexes = new ArrayList<Rx>();
		String[] positivesAndNegatives = selector.split(" -");
		for (String subSelector : positivesAndNegatives) {
			if (positiveRegex == null) {
				String s1 = backSlashDots(subSelector);
				String s2 = s1.replace(" ", ").* .*(");
				positiveRegex = Rx.createRx("(" + s2 + ")");
			} else {
				String s1 = backSlashDots(subSelector);
				String s2 = s1.replace(" ", ".* .*");
				negativeRegexes.add(Rx.createRx(s2));
			}
		}
	}

	private String backSlashDots(String subSelector) {
		return subSelector.trim().replace(".", "\\.");
	}
}
