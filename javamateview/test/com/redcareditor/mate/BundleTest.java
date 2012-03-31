package com.redcareditor.mate;

import static org.junit.Assert.*;

import org.junit.Before;
import org.junit.Test;

public class BundleTest {

	@Before
	public void setUp() {
		Bundle.loadBundles("input/");
	}

	@Test
	public void shouldHaveCreatedCorrectBundles() {
		String[] bundleNames = new String[] { "Apache", "Ruby", "HTML", "CSS", "JavaScript", "Perl" };
		for (String bundleName : bundleNames) {
			containsBundleNamed(bundleName);
		}
		assertEquals(11, Bundle.getBundles().size());
	}

	private void containsBundleNamed(String bundleName) {
		assertNotNull(Bundle.getBundleByName(bundleName));
	}

	@Test
	public void shouldHaveCreatedCorrectGrammars() {
		assertEquals(1, Bundle.getBundleByName("Apache").getGrammars().size());
		assertEquals(1, Bundle.getBundleByName("Ruby").getGrammars().size());
	}
}
