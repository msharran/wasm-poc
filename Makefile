.PHONY: build, run, login, shell

build:
	cd go && make

run:
	ruby main.rb

shell:
	docker run -it -v /Users/shmurali/play:/workspace -w=/workspace ruby:2.3.8 /bin/bash

run_ruby_23:
	LD_PRELOAD=./lib/libfoo.so ruby main.rb
