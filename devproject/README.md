Code explenation:

When running main.py, the file calles for ec2_with_alb.j2 a template and makes terraform file with inputs from the user.
The code can run terraform init, plan and apply after the terraform file has been created.
Last step for main.py is to print the outputs and errors to take care of.

validate.py - gets the outputs from the terraform file and with boto3 checks and confirmes all checks out and validated. (EC2, Load Balancer)
then saves everything as a json.

______________________________________________________________________________

.
├── main.py                   # Main deployment script using Jinja2 and python-terraform
├── validate.py               # Validation script using Boto3
├── templates/
│   └── ec2_with_alb.j2       # Jinja2 Terraform template
├── terraform/                # Generated Terraform files
│   ├── main.tf
│   ├── outputs.tf
├── aws_validation.json       # JSON output from Boto3 validation
├── infra_diagram.png         # Architecture diagram (optional)
└── README.md