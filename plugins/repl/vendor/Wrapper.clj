(ns redcar.repl.Wrapper
  (:require [org.enclojure.repl.main])
  (:gen-class
    :state state
    :init init
    :methods [[getResult [] String]
              [sendToRepl [String] void]]))

(defn -init []  
  [[] (org.enclojure.repl.main/create-clojure-repl)])

(defn -getResult [this]
  ((:result-fn (.state this))))

(defn -sendToRepl [this expr]
  ((:repl-fn (.state this)) expr))
