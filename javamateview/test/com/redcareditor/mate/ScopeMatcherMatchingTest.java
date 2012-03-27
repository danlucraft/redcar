
package com.redcareditor.mate;

import static org.junit.Assert.*;
import org.junit.Test;

public class ScopeMatcherMatchingTest {
	public boolean testMatch(String a, String b) {
		return ScopeMatcher.testMatch(a, b);
	}
	
	@Test
	public void shouldMatchSimpleWords() {
		assertTrue(testMatch("comment", "ruby.comment"));
		assertFalse(testMatch("string", "ruby.comment"));
		assertTrue(testMatch("source.ruby", "source.ruby comment"));
	}
	
	@Test
	public void shouldNotMatchSubstrings() {
		assertFalse(testMatch("source.c", "source.coffee"));
	}
	
	@Test
	public void shouldTransformDots() {
		assertFalse(testMatch("source.ruby", "sourcearuby comment"));
		assertTrue(testMatch("source.ruby", "source.ruby comment"));
	}
	
	@Test
	public void shouldMatchAtSeparateLocationsInTheString() {
		assertTrue(testMatch("ruby string", "ruby interpolated string.quoted"));
	}

	@Test
	public void shouldMatchWithSelectorOrs() {
		assertTrue(testMatch("string, comment", "ruby.string"));
		assertTrue(testMatch("string, comment", "ruby.comment"));
	}

	@Test
	public void shouldDealWithNegativeMatches() {
		assertTrue(testMatch("string - string.double", "ruby.string"));
		assertFalse(testMatch("string - string.double", "ruby.string.double"));
	}

	@Test
	public void shouldDealWithMultipleNegativeMatches() {
		assertFalse(testMatch("string - string.double - comment", "ruby.string.double"));
		assertFalse(testMatch("string - string.double - comment", "ruby.string.comment"));
	}
}



