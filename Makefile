
SHELL := /bin/bash


PROJECT := mynotebook
LOGIN   := ubuntu@18.194.22.206
# ubuntu@18.196.84.52 
# ec2-user@ec2-35-157-157-97.eu-central-1.compute.amazonaws.com
SSH     := ssh -A -i ~/.ssh/id_martinvirtel_server_2016.pub $(LOGIN)
REMOTEDIR := /home/ubuntu/projekte/$(PROJECT)

build:
	docker build . -t $(PROJECT)

run:
	export work=$$(pwd)/work ;\
	echo mkdir -p $$work ;\
	sudo chown -R $$(id -u) $$work ; \
	docker run -it --rm -p 8888:8888 \
		-e GEN_CERT=yes \
		-e GRANT_SUDO=yes \
		-e NB_UID=$$(id -u)\
		-e NB_GID=$$(id -g)\
		-u root \
		--name $(PROJECT) \
		-v $$work:/home/jovyan/work \
		$(PROJECT) $(PARAM)


get-token:
	docker logs $(PROJECT) | grep token=


remote: 
	expect -c 'spawn $(SSH); send "mkdir -p $(REMOTEDIR); cd $(REMOTEDIR); tmux new-session -s $(PROJECT) || tmux attach -t $(PROJECT)\r"; sleep 0.5; send  "eval \$$(tmux show-env -g |grep '^SSH_A')\r"; interact '

remote-exec:
	$(SSH) $(PARAM)


#		-v $$(pwd)/site-packages:/opt/conda/lib/python3.6/site-packages 
#
#
fargate-logs:
	xdg-open 'https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logStream:group=/ecs/jupyter-task-definitien'


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



INSTANCE := i-045fdc3f16c85b557

start-instance:
	aws ec2 start-instances --instance-ids=$(INSTANCE)

stop-instance:
	aws ec2 stop-instances --instance-ids=$(INSTANCE)

query-instance:
	printf "$(INSTANCE) state:"
	aws ec2 describe-instances --instance-ids=$(INSTANCE) --query=Reservations[].Instances[].State.Name --output=text

