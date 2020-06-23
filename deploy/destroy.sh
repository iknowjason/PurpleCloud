#!/bin/sh

terraform destroy -var-file=terraform.tfvars -auto-approve
