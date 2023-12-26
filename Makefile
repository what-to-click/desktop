.PHONY: code
code: 
	dart run build_runner build -d

.PHONY: code-and-watch
code-and-watch: 
	dart run build_runner watch -d