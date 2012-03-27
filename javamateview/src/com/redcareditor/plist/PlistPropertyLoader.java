package com.redcareditor.plist;

import java.lang.reflect.Field;

import com.redcareditor.onig.Rx;

/**
 * This class will load properties from the given {@link Dict} into the object.
 * It uses reflection, so beware of them typos. :D
 * 
 * @author kungfoo
 */
public class PlistPropertyLoader {
	private Dict dict;
	private Object object;

	public PlistPropertyLoader(Dict dict, Object obj) {
		this.dict = dict;
		this.object = obj;
	}

	public void loadStringProperty(String propertyName) {
		String value = dict.getString(propertyName);
		trySettingProperty(propertyName, value);
	}

	public void loadRegexProperty(String propertyName) {
		String value = dict.getString(propertyName);
		Rx regex = Rx.createRx(value);
		trySettingProperty(propertyName, regex);
	}

	private void trySettingProperty(String propertyName, Object value) {
		try {
			Field prop = object.getClass().getDeclaredField(propertyName);
			if (value != null) {
				prop.set(object, value);
			}
		} catch (Exception e) {
			System.out.println(String.format("Can't set %s = %s on object %s", propertyName, value, object.toString()));
			e.printStackTrace();
		}
	}
}
