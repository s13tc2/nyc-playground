.DEFAULT_GOAL := help

# From https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build_citibike_api
build_citibike_api: ## Build the Citi Bike API Docker image
	docker build --no-cache -t airflowbook/chapter14_citibike_api services/citibike_api

.PHONY: build_citibike_db
build_citibike_db: ## Build the Citi Bike DB Docker image
	docker build --no-cache -t airflowbook/chapter14_citibike_db services/citibike_db

.PHONY: build_citibike
build_citibike: build_citibike_api build_citibike_db ## Build the Citi Bike API & DB Docker images

.PHONY: build_taxi_fileserver
build_taxi_fileserver: ## Build the NYC Yellow Taxi fileserver Docker image
	docker build --no-cache -t airflowbook/chapter14_taxi_fileserver services/taxi_fileserver

.PHONY: build_taxi_db
build_taxi_db: ## Build the NYC Yellow Taxi DB Docker image
	docker build --no-cache -t airflowbook/chapter14_taxi_db services/taxi_db

.PHONY: build_taxi
build_taxi: build_taxi_fileserver build_taxi_db ## Build the NYC Yellow Taxi fileserver & DB Docker images

.PHONY: build_airflow
build_airflow: ## Build Airflow with additional dependencies
	docker build --no-cache -t airflowbook/chapter14_airflow services/airflow

.PHONY: build_nyc_transportation_api
build_nyc_transportation_api: ## Build NYC Transportation API
	docker build --no-cache -t airflowbook/chapter14_nyc_transportation_api services/nyc_transportation_api

.PHONY: build_all
build_all: build_citibike build_taxi build_airflow build_nyc_transportation_api ## Build all Docker images (warning: takes long!)

####################################################################################################################
# Set up cloud infrastructure

tf-init:
	terraform -chdir=./terraform init

infra-up:
	terraform -chdir=./terraform apply

infra-down:
	terraform -chdir=./terraform destroy

infra-config:
	terraform -chdir=./terraform output

####################################################################################################################
# Port forwarding to local machine

cloud-metabase:
	terraform -chdir=./terraform output -raw private_key > private_key.pem && chmod 600 private_key.pem && ssh -o "IdentitiesOnly yes" -i private_key.pem ubuntu@$$(terraform -chdir=./terraform output -raw ec2_public_dns) -N -f -L 3001:$$(terraform -chdir=./terraform output -raw ec2_public_dns):3000 && open http://localhost:3001 && rm private_key.pem

cloud-airflow:
	terraform -chdir=./terraform output -raw private_key > private_key.pem && chmod 600 private_key.pem && ssh -o "IdentitiesOnly yes" -i private_key.pem ubuntu@$$(terraform -chdir=./terraform output -raw ec2_public_dns) -N -f -L 8081:$$(terraform -chdir=./terraform output -raw ec2_public_dns):8080 && open http://localhost:8081 && rm private_key.pem

####################################################################################################################
# Helpers

ssh-ec2:
	terraform -chdir=./terraform output -raw private_key > private_key.pem && chmod 600 private_key.pem && ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i private_key.pem ubuntu@$$(terraform -chdir=./terraform output -raw ec2_public_dns) && rm private_key.pem
