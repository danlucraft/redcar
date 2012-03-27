package com.redcareditor.mate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.redcareditor.plist.Dict;
import com.redcareditor.plist.PlistNode;

public class Pattern {
	public Grammar grammar;
	public String name;
	public boolean disabled;

	public static Pattern createPattern(List<Pattern> allPatterns, Dict dict) {
		if (dict.containsElement("match")) {
			return new SinglePattern(allPatterns, dict);
		}

		if (dict.containsElement("include")) {
			return new IncludePattern(dict);
		}

		if (dict.containsElement("begin")) {
			return new DoublePattern(allPatterns, dict);
		}

		return null;
	}

	public static Map<Integer, String> makeCapturesFromPlist(Dict pd) {
		if (pd == null)
			return new HashMap<Integer, String>();
		Dict pcd;
		String ns;
		Map<Integer, String> captures = new HashMap<Integer, String>();
		for (String sCapnum : pd.value.keySet()) {
			int capnum = Integer.parseInt(sCapnum);
			pcd = pd.getDictionary(sCapnum);
			ns = pcd.getString("name");
//			System.out.printf("capture: %d, %s\n", capnum, ns);
			captures.put((Integer) capnum, ns);
		}
		return captures;
	}

	public static void replaceIncludePatterns(List<Pattern> patterns, Grammar grammar) {
		replaceRepositoryIncludes(patterns, grammar);
		replaceBaseAndSelfIncludes(patterns, grammar);
	}

	public static void replaceRepositoryIncludes(List<Pattern> patterns, Grammar grammar) {
		int i = 0;
		while (i < patterns.size()) {
			Pattern p = patterns.get(i);
			if (p instanceof IncludePattern && p.name.startsWith("#")) {
				// System.out.printf("repo include: %s\n", p.name);
				String reponame = p.name.substring(1, p.name.length());
				List<Pattern> repositoryEntryPatterns = grammar.repository.get(reponame);
				if (repositoryEntryPatterns != null) {
					// System.out.printf("  got %d patterns\n", repositoryEntryPatterns.size());
					patterns.remove(i);
					patterns.addAll(i, repositoryEntryPatterns);
					i--;
				} else {
					System.out.printf("warning: couldn't find repository key '%s' in grammar '%s'\n", reponame,
							grammar.name);
				}
			}
			i++;
		}
	}

	public static void replaceBaseAndSelfIncludes(List<Pattern> patterns, Grammar grammar) {
		boolean alreadySelf = false; // some patterns have $self twice
		Grammar ng;
		int i = 0;
		while (i < patterns.size()) {
			Pattern p = patterns.get(i);
			if (p instanceof IncludePattern) {
				if (p.name.startsWith("$")) {
					if ((p.name.equals("$self") || p.name.equals("$base")) && !alreadySelf) {
						alreadySelf = true;
						patterns.remove(i);
						patterns.addAll(i, grammar.patterns);
						i--;
					}
				//} else if ((ng = Grammar.findByScopeName(p.name)) != null) {
				//	ng.initForUse();
				//	patterns.remove(i);
				//	patterns.addAll(i, ng.patterns);
				//	i--;
				}
			}
			i++;
		}
	}

	private static void removePatterns(List<Pattern> patlist, List<Pattern> ps) {
		for (Pattern p : ps) {
			patlist.remove(p);
		}
	}

	private static void addPatterns(List<Pattern> patlist, List<Pattern> ps) {
		for (Pattern p : ps) {
			patlist.add(p);
		}
	}

	public void setDisabled(Dict dict) {
		PlistNode<?> plistNode = dict.value.get("disabled");
		int intn;
		if (plistNode != null) {
			if (plistNode.value instanceof String) {
				String strn = dict.getString("disabled");
				intn = Integer.parseInt(strn);
			}
			else {
				intn = dict.getInt("disabled");
			}
			switch (intn) {
			case 1:
				disabled = true;
				break;
			default:
				disabled = false;
				break;
			}
		} else {
			disabled = false;
		}
	}
	
	public String prettyName() {
		if (name == null) {
			if (this instanceof SinglePattern) {
				return ((SinglePattern) this).match.pattern;
			}
			else if (this instanceof DoublePattern) {
				return ((DoublePattern) this).begin.pattern;
			}
			else {
				return "unknown";
			}
		}
		else {
			return name;
		}
	}
}
