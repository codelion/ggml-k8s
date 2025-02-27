# Include environment variables from the .env file and helper functions
ifneq (,$(wildcard ./.env))
   include .env
   export
endif
MODEL_COUNT=$(shell yq eval '.models | length' models.yaml)
.PHONY: generate-config-files
generate-config-files:
	python -m _scripts.generate_config_files --acm_certificate_arn $(ACM_CERTIFICATE_ARN) --domain $(DOMAIN_NAME)

# AWS Cloud infrastructure
.PHONY: deploy-terraform-aws
deploy-terraform-aws: generate-config-files
	( \
		cd terraform/aws && \
		terraform init && \
		terraform apply -var="aws_region=$(AWS_REGION)" -var="model_count=$(MODEL_COUNT)" -var="ec2_instance_type=$(EC2_INSTANCE_TYPE)" -var="min_cluster_size=$(MIN_CLUSTER_SIZE)" \
	)

.PHONY: init-cluster-aws
init-cluster-aws: generate-config-files
	aws eks --region $(AWS_REGION) update-kubeconfig --name LlamaCppEKSCluster && \
	helm install local-ai kubernetes/charts/local-ai -f kubernetes/values.yaml --namespace default --set awsRegion=$(AWS_REGION) && \
	sleep 42 && \
	chmod +x ./_scripts/update_route53_record.sh && \
	./_scripts/update_route53_record.sh $(DOMAIN_NAME)

.PHONY: destroy-terraform-aws
destroy-terraform-aws:
	( \
		helm uninstall local-ai || true && \
		cd terraform/aws && \
		terraform init && \
		terraform destroy -var="aws_region=$(AWS_REGION)" || true && \
		chmod +x ./delete-cluster-sgs.sh && \
		./delete-cluster-sgs.sh && \
		terraform destroy -var="aws_region=$(AWS_REGION)" -auto-approve \
	)

# Kubernetes infrastructure
.PHONY: update-kubernetes-cluster
update-kubernetes-cluster: generate-config-files
	helm upgrade local-ai kubernetes/charts/local-ai -f kubernetes/values.yaml --namespace default --set awsRegion=$(AWS_REGION)

### TODO: Add support for other cloud providers
# Azure Cloud infrastructure
.PHONY: deploy-terraform-azure
deploy-terraform-azure: 
	echo "Not implemented yet"
	
# GCP Cloud infrastructure
.PHONY: deploy-terraform-gcp
deploy-terraform-gcp: 
	echo "Not implemented yet"
