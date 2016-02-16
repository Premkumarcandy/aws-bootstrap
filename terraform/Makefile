.PHONY: all plan apply destroy graph

all: plan apply

plan:
	terraform plan -var-file terraform.tfvars -out terraform.tfplan

apply:
	terraform apply -var-file terraform.tfvars

destroy:
	terraform plan -destroy -var-file terraform.tfvars -out terraform.tfplan
	terraform apply terraform.tfplan
graph:
	terraform graph | dot -Tpng > graph.png

