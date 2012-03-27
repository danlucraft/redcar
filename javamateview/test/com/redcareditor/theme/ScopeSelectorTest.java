package com.redcareditor.theme;

import java.util.List;

import org.junit.Test;
import static org.junit.Assert.*;

public class ScopeSelectorTest {
	@Test
	public void testSinglePositiveSelector(){
		String selector = "entity.name.function";
		List<ScopeSelector> selectors = ScopeSelector.compile(selector);
		assertEquals(1, selectors.size());
		
		ScopeSelector s = selectors.get(0);
		assertEquals("(entity\\.name\\.function)", s.positiveRegex.pattern);
	}
	
	@Test
	public void testMultiplePositiveSelectors(){
		String selector = "meta.tag, declaration.tag, entity.name.tag, entity.other.attribute-name";
		List<ScopeSelector> selectors = ScopeSelector.compile(selector);
		assertEquals(4, selectors.size());
		
		ScopeSelector s1 = selectors.get(0);
		assertEquals("(meta\\.tag)", s1.positiveRegex.pattern);
		
		ScopeSelector s3 = selectors.get(2);
		assertEquals("(entity\\.name\\.tag)", s3.positiveRegex.pattern);
	}
	
	@Test
	public void testPositiveAndNegativeSelector(){
		String selector = "source.ruby string - string source";
		List<ScopeSelector> selectors = ScopeSelector.compile(selector);
		// TODO: test something here!
	}
}
