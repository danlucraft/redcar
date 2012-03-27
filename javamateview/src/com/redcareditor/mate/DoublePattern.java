package com.redcareditor.mate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.joni.exception.ValueException;

import com.redcareditor.onig.Rx;
import com.redcareditor.plist.Dict;
import com.redcareditor.plist.PlistNode;

public class DoublePattern extends Pattern {
	public String contentName;
	public Rx begin;
	public Rx end;
	public String endString;
	public String beginString;
	public Map<Integer, String> beginCaptures;
	public Map<Integer, String> endCaptures;
	public Map<Integer, String> bothCaptures;
	public List<Pattern> patterns;
	public boolean hasReplacedGrammarIncludes = false;
	
	public DoublePattern() {}
	
	public DoublePattern(List<Pattern> grammarPatterns, Dict dict) {
		name = dict.getString("name");
//		System.out.printf("new DoublePattern name: %s\n", name);
		try {
			setDisabled(dict);
			endString = dict.getString("end");
			contentName = dict.getString("contentName");
			begin = Rx.createRx(dict.getString("begin"));

			loadCaptures(dict);
			loadPatterns(grammarPatterns, dict);
			grammarPatterns.add(this);
		}
		catch(ValueException e) {
			System.out.printf("joni.exception.ValueException: %s in %s\n", e.getMessage(), dict.getString("begin"));
		}
	}

	private void loadPatterns(List<Pattern> grammarPatterns, Dict dict) {
		patterns = new ArrayList<Pattern>();
		if (dict.containsElement("patterns")) {
			for (PlistNode<?> plistPattern : dict.getArray("patterns")) {
				Pattern subPattern = Pattern.createPattern(grammarPatterns, (Dict) plistPattern);
				if (subPattern != null) {
					patterns.add(subPattern);
				}
			}
		}
	}

	private void loadCaptures(Dict dict) {
		if (dict.containsElement("beginCaptures")) {
			beginCaptures = Pattern.makeCapturesFromPlist(dict.getDictionary("beginCaptures"));
		}
		if (dict.containsElement("captures")) {
			bothCaptures = Pattern.makeCapturesFromPlist(dict.getDictionary("captures"));
		}
		if (dict.containsElement("endCaptures")) {
			endCaptures = Pattern.makeCapturesFromPlist(dict.getDictionary("endCaptures"));
		}
	}
	
	public void replaceGrammarIncludes() {
		if (hasReplacedGrammarIncludes)
			return;
		Grammar ng;
		int i = 0;
		while (i < patterns.size()) {
			Pattern p = patterns.get(i);
			if (p instanceof IncludePattern) {
				if ((ng = Grammar.findByScopeName(p.name)) != null) {
					ng.initForUse();
					patterns.remove(i);
					patterns.addAll(i, ng.patterns);
					i--;
				}
			}
			i++;
		}
		hasReplacedGrammarIncludes = true;
	}

}
