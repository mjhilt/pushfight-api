.DELETE_ON_ERROR:


.PHONY: build run clean

build : deploy/elm.js deploy/index.html

clean:
	rm deploy/*

deploy/elm.js deploy/index.html: $(shell find pushfight-viz -name "*.elm") pushfight-viz/index.html
	cd pushfight-viz/src && elm make Main.elm --output ../../deploy/elm.js
	cp pushfight-viz/index.html deploy/index.html 

run: build
	python server.py
