package com.redcareditor.mate;

import java.util.ArrayList;
import java.util.List;

import com.redcareditor.onig.Match;
import com.redcareditor.onig.Range;
import com.redcareditor.onig.Rx;

public class ScopeMatcher {
	public Rx pos_rx;
	public List<Rx> neg_rxs;

	public static List<Integer> occurrences(String target, String find) {
		List<Integer> positions = new ArrayList<Integer>();
		int fromIndex = 0;
		int newIndex = -1;
		while ((newIndex = target.indexOf(find, fromIndex)) != -1) {
			positions.add(newIndex);
			fromIndex = newIndex + 1;
		}
		return positions;
	}

	// returns 1 if m1 is better than m2, -1 if m1 is worse than m2, 0 if
	// equally good
	public static int compareMatch(String scopeString, Match m1, Match m2) {
		List<Integer> spaceIxs = occurrences(scopeString, " ");
		int max_cap1 = m1.numCaptures();
		int max_cap2 = m2.numCaptures();
		int cap1_ix, cap1_el_ix, len1;
		int cap2_ix, cap2_el_ix, len2;
		for (int i = 0; i < Math.min(max_cap1, max_cap2); i++) {
			// first try element depth:
			Range capture1 = m1.getCapture(max_cap1 - 1 - i);
			Range capture2 = m2.getCapture(max_cap2 - 1 - i);
			
			cap1_ix = capture1.start;
			cap2_ix = capture2.start;
			cap1_el_ix = ScopeMatcher.sorted_ix(spaceIxs, cap1_ix);
			cap2_el_ix = ScopeMatcher.sorted_ix(spaceIxs, cap2_ix);
			if (cap1_el_ix > cap2_el_ix) {
				return 1;
			} else if (cap1_el_ix < cap2_el_ix) {
				return -1;
			}

			// next try length of match
			len1 = capture1.end - cap1_ix;
			len2 = capture2.end - cap2_ix;
			if (len1 > len2) {
				return 1;
			} else if (len1 < len2) {
				return -1;
			}
		}
		return 0;
	}

	private static int sorted_ix(List<Integer> ixs, int val) {
		if (ixs.size() == 0)
			return 0;
		if (val < ixs.get(0))
			return 0;
		if (ixs.size() == 1) {
			if (val > ixs.get(0))
				return 1;
			else
				return 0;
		} else {
			for (int i = 0; i < ixs.size() - 1; i++) {
				if (val > ixs.get(i) && val < ixs.get(i + 1))
					return i + 1;
			}
			return ixs.size();
		}
	}

	// this method is mainly for testing in the Ruby specs
	public static String testRank(String selector_a, String selector_b, String scope_string) {
		Match m1 = match(selector_a, scope_string);
		Match m2 = match(selector_b, scope_string);
		int r = compareMatch(scope_string, m1, m2);
		if (r > 0) {
			return selector_a;
		} else if (r == 0) {
			return selector_a + " == " + selector_b;
		} else {
			return selector_b;
		}
	}

	public static boolean testMatch(String selectorString, String scopeString) {
		Match m = getMatch(selectorString, scopeString);
		return (m != null);
	}

	public static Match getMatch(String selectorString, String scopeString) {
		Match m = match(selectorString, scopeString);
		if (m != null) {
//			System.out.printf("%d\n", m.numCaptures());
			Range firstCapture = m.getCapture(0);
//			System.out.printf("test_match('%s', '%s') == %d\n", selectorString, scopeString, firstCapture.start);
		} else {
//			System.out.printf("test_match('%s', '%s') == null\n", selectorString, scopeString);
		}
		return m;
	}

	public static Match match(String selectorString, String scopeString) {
		List<ScopeMatcher> matchers = ScopeMatcher.compile(selectorString);
		for (ScopeMatcher matcher : matchers) {
			Match m;
			if ((m = testMatchRe(matcher.pos_rx, matcher.neg_rxs, scopeString)) != null)
				return m;
		}
		return null;
	}

	public static List<ScopeMatcher> compile(String selectorString) {
		List<ScopeMatcher> ms = new ArrayList<ScopeMatcher>();
		// FIXME should validate and throw UTF8 error if bad.
		String[] scopeOrs1 = selectorString.split(",");
//		System.out.printf("match: selector: '%s'\n", selectorString);
		for (String selectorString1 : scopeOrs1) {
			ScopeMatcher m = new ScopeMatcher();
			m.neg_rxs = new ArrayList<Rx>();
			String[] positivesAndNegatives = selectorString1.split(" -");
			for (String subSelectorString : positivesAndNegatives) {
				if (m.pos_rx == null) {
					String s1 = subSelectorString.trim().replaceAll("\\.", "\\\\.");
					String s2 = s1.replaceAll(" ", ").* .*(");
//					System.out.printf("positive '%s'\n", "(" + s2 + ")");
					m.pos_rx = Rx.createRx("^(?:.*[^A-Za-z])?(" + s2 + ")(?:[^A-Za-z].*)?$");
				} else {
					String s1 = subSelectorString.trim().replaceAll("\\.", "\\\\.");
					String s2 = s1.trim().replaceAll(" ", ".* .*");
//					System.out.printf("negative '%s'\n", s2);
					m.neg_rxs.add(Rx.createRx(s2));
				}
			}
			ms.add(m);
		}
		return ms;
	}

	public static Match testMatchRe(Rx positiveSelectorRegex, List<Rx> negativeSelectorRegexes, String scopeString) {
		Match m = positiveSelectorRegex.search(scopeString, 0, scopeString.length());
		if (m != null) {
			for (Rx negRx : negativeSelectorRegexes) {
				Match m1 = negRx.search(scopeString, 0, scopeString.length());
				if (m1 != null) {
					return null;
				}
			}
			return m;
		} else {
			return null;
		}
	}

}