
package com.redcareditor.mate;

import static org.junit.Assert.*;

import org.junit.Test;

public class ScopeMatcherRankingTest {
	public String testRank(String a, String b, String scope) {
		return ScopeMatcher.testRank(a, b, scope);
	}

	@Test
	public void shouldRankTwoMatchesByTheirElementDepth() {
		assertEquals("string", testRank("string", "ruby", "ruby string"));
	}

	@Test
	public void shouldRankTwoMatchesByElementDepthNotStringDepth() {
		assertEquals("string == quoted", testRank("string", "quoted", "string.quoted"));
	}
		
	@Test
	public void shouldRankTwoMatchesByTheLengthOfTheMatch() {
		assertEquals("string.quoted", testRank("string.quoted", "string", "string.quoted"));
	}
	
	@Test
	public void shouldMoveUpTheElementMatchesInCaseOfATieAndCheckElementDepth() {
		assertEquals("ruby string", testRank("ruby string", "source string", "source ruby string"));
		assertEquals("ruby string", testRank("source string", "ruby string", "source ruby string"));
	}
	
	@Test
	public void shouldMoveUpTheElementMatchesInCaseOfATieAndCheckMatchLength() {
		assertEquals("source.ruby string", testRank("ruby string", "source.ruby string", "source.ruby string"));
	}
	

}
