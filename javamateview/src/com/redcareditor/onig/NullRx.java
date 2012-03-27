package com.redcareditor.onig;

public class NullRx extends Rx{
	private static NullRx instance;
	
	public static NullRx instance(){
		if(instance == null){
			instance = new NullRx();
		}
		return instance;
	}
	
	private NullRx(){}
	
	@Override
	public String toString() {
		return "NullRx";
	}
	
	@Override
	public Match search(String line) {
		return NullMatch.instance();
	}
	
	@Override
	public Match search(String target, int start, int end) {
		return search(target);
	}
}
