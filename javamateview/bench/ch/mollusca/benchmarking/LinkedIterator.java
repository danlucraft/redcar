package ch.mollusca.benchmarking;

import java.util.Iterator;

public class LinkedIterator<T> implements Iterator<T>{
	private LinkedList<T> list;
	private LinkedNode<T> current;
	
	public LinkedIterator(LinkedList<T> list){
		this.list = list;
		this.current = list.getRoot();
	}
	
	public boolean hasNext() {
		if(list.size() == 0){
			return false;
		}
		return current != null;
	}
	
	public T next() {
		LinkedNode<T> last = current;
		current = current.getNext();
		return last.getData();
	}
	
	public void remove() {
		throw new UnsupportedOperationException("no deleting here!!");
	}
	
	public void rewind(){
		current = list.getRoot();
	}
}
