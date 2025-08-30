APP ?= my-app
PM  ?= npm
.PHONY: bootstrap
bootstrap:
	./bootstrap.sh $(APP) $(PM)
