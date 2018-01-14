
SHELL := /bin/bash

include config.makefile

build:
	docker build . -t $(PROJECT)

port ?= 8888
mode ?= -it
cert ?= no
run:
	{ \
	echo PARAMETERS: port=$(port) mode=$(mode) param=$(param) cert=$(cert);\
	export work=$$(pwd)/work ;\
	if [ "$(cert)" == "yes" ] ; then \
	   export certe="-e GEN_CERT=yes" ; \
	else \
	   export certe="" ;\
	fi ;\
	mkdir -p $$work ;\
	sudo chown -R $$(id -u) $$work ; \
	docker run $(mode) --rm -p $(port):8888 \
                $$certe \
		-e GRANT_SUDO=yes \
		-e NB_UID=$$(id -u)\
		-e NB_GID=$$(id -g)\
		-u root \
		--name $(PROJECT) \
		-v $$work:/home/jovyan/work \
		$(PROJECT) $(param) ; \
	}


stop:
	docker stop $(PROJECT)

status: 
	docker ps --filter name=$(PROJECT)


exec ?= jupyter notebook list
exec:
	{ \
	echo PARAMETERS: exec=$(exec) ;\
	docker exec -it $(PROJECT) $(exec) ;\
	}


encode-password: 
	{ \
	echo cleartext=$(cleartext) ;\
	docker exec -it $(PROJECT) python -c 'from IPython.lib import passwd; print(passwd("$(cleartext)"))' ;\
	}

remote: 
	expect -c 'spawn $(SSH); send "mkdir -p $(REMOTEDIR); cd $(REMOTEDIR); tmux new-session -s $(PROJECT) || tmux attach -t $(PROJECT)\r"; sleep 0.5; send  "eval \$$(tmux show-env -g |grep '^SSH_A')\r"; interact '

remote-exec:
	$(SSH) $(PARAM)



DEPLOYKEYFILE=$(REMOTEDIR)/.deploykey

deploy-key :
	{ \
	mkdir -p .deploy ;\
	ssh-keygen  -t rsa -b 4096 -P "" -C "$(PROJECT) deploy key" -f .deploy/$(PROJECT)_deploy ;\
	}


push-deploy-key-to-remote :
	{ \
	cat .deploy/$(PROJECT)_deploy | $(SSH) $(PARAM) " cat - >$(DEPLOYKEYFILE); chmod og-rw $(DEPLOYKEYFILE) "  ;\
	echo Add to ~/.ssh/config: ;\
	printf "Host $(PROJECT)-github\n\tHostname github.com\n\tUser git\n\tIdentity $(DEPLOYKEYFILE)\n\n" ;\
	echo Then clone with: ;\
	printf "git clone $(shell git remote -v | awk -n '/fetch/ { print gensub(/^[^:]+/,"git@$(PROJECT)-github",$$2); }')\n" ;\
	}




start-instance:
	$(AWS_CREDENTIALS) aws ec2 start-instances --instance-ids=$(INSTANCE)

stop-instance:
	$(AWS_CREDENTIALS) aws ec2 stop-instances --instance-ids=$(INSTANCE)

query-instance:
	@printf "$(INSTANCE) state: " ;\
	$(AWS_CREDENTIALS) aws ec2 describe-instances --instance-ids=$(INSTANCE) --query=Reservations[].Instances[].State.Name --output=text

