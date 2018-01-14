

AWS_CREDENTIALS := AWS_DEFAULT_REGION=eu-central-1 AWS_PROFILE=martin.virtel@dpa-info.com 
PROJECT := mynotebook
LOGIN   := ubuntu@18.194.22.206
# ubuntu@18.196.84.52 
# ec2-user@ec2-35-157-157-97.eu-central-1.compute.amazonaws.com
SSH     := ssh -A -i ~/.ssh/id_martinvirtel_server_2016.pub $(LOGIN)
REMOTEDIR := /home/ubuntu/projekte/$(PROJECT)
INSTANCE := i-045fdc3f16c85b557


start-service:
	$(MAKE) run port=18818  mode=-d cert=no param="start-notebook.sh --NotebookApp.allow_origin='*' --NotebookApp.password='sha1:2a48daef913b:528211e379b6e19a8b574db096d246f7d61349cf'" 



