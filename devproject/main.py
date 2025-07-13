from jinja2 import Environment, FileSystemLoader
from python_terraform import Terraform
import os
import sys
import subprocess

def render_template_to_tf(user_data):
    env = Environment(loader=FileSystemLoader('templates'))
    template = env.get_template('ec2_with_alb.j2')
    rendered = template.render(user_data)

    os.makedirs('terraform', exist_ok=True)
    with open('terraform/main.tf', 'w') as f:
        f.write(rendered)

    print("Terraform configuration written to terraform/main.tf")

def run_terraform():
    tf = Terraform(working_dir='terraform')
    print("Running Terraform Init...")
    return_code, stdout, stderr = tf.init()
    print(stdout)

    if return_code != 0:
        print("Terraform init failed")
        sys.exit(1)

    print("Running Terraform Plan...")
    return_code, stdout, stderr = tf.plan()
    print(stdout)

    print("Running Terraform Apply...")
    return_code, stdout, stderr = tf.apply(skip_plan=True, capture_output=True)
    print(stdout)

    if return_code != 0:
        print("Terraform apply failed:", stderr)
        sys.exit(1)

def show_outputs():
    tf = Terraform(working_dir='terraform')
    return_code, stdout, stderr = tf.output()
    print("Terraform Outputs:")
    print(stdout)

if __name__ == "__main__":
    user_input = {
        "ami": "ami-02bf8ce06a8ed6092",
        "instance_type": "t3.small",
        "availability_zones": ["us-east-2a", "us-east-2b"],
        "region": "us-east-2",
        "load_balancer_name": "my-alb"
    }

    try:
        render_template_to_tf(user_input)
        run_terraform()
        show_outputs()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

