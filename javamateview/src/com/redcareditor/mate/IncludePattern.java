package com.redcareditor.mate;

import com.redcareditor.plist.Dict;

public class IncludePattern extends Pattern {
	public IncludePattern(Dict dict) {
		name = dict.getString("include");
//		System.out.printf("ip: %s\n", name);
	}
}
