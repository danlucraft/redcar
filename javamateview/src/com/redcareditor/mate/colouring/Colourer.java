package com.redcareditor.mate.colouring;

import java.util.List;

import com.redcareditor.mate.Scope;
import com.redcareditor.theme.Theme;

public interface Colourer {

	public abstract void setTheme(Theme theme);

	public abstract Theme getTheme();
	
	public abstract void setGlobalColours();

}