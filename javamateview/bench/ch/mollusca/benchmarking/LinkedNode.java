package ch.mollusca.benchmarking;


public class LinkedNode<T>{
	private LinkedNode<T> next;
	private T data;
	
	public LinkedNode(T data){
		this.data = data;
	}
	
	protected void setNext(LinkedNode<T> next) {
		this.next = next;
	}
	
	public void insert(LinkedNode<T> node){
		this.next = node;
	}
	
	public T getData(){
		return data;
	}
	
	public LinkedNode<T> getNext() {
		return next;
	}
}
