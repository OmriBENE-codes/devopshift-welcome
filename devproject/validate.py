import boto3
import json
import subprocess

def get_terraform_outputs():
    result = subprocess.run(["terraform", "output", "-json"], capture_output=True, text=True, cwd="terraform")
    if result.returncode != 0:
        raise Exception("Failed to get Terraform outputs")

    outputs = json.loads(result.stdout)
    return {
        "instance_id": outputs["instance_id"]["value"],
        "public_ip": outputs["public_ip"]["value"],
        "load_balancer_dns": outputs["load_balancer_dns_name"]["value"]
    }

def validate_resources(terraform_data, region="us-east-2"):
    ec2 = boto3.client("ec2", region_name=region)
    elbv2 = boto3.client("elbv2", region_name=region)

    instance_id = terraform_data["instance_id"]
    public_ip = terraform_data["public_ip"]
    lb_dns_name = terraform_data["load_balancer_dns"]

    # Get EC2 instance details
    ec2_response = ec2.describe_instances(InstanceIds=[instance_id])
    instance = ec2_response["Reservations"][0]["Instances"][0]
    state = instance["State"]["Name"]
    actual_ip = instance.get("PublicIpAddress", "")

    # Get ALB details
    alb_response = elbv2.describe_load_balancers()
    found_dns = None
    for lb in alb_response["LoadBalancers"]:
        if lb["DNSName"] == lb_dns_name:
            found_dns = lb["DNSName"]
            break

    if not found_dns:
        raise Exception("ALB not found in boto3 response")

    validation_data = {
        "instance_id": instance_id,
        "instance_state": state,
        "public_ip": actual_ip,
        "load_balancer_dns": found_dns
    }

    with open("aws_validation.json", "w") as f:
        json.dump(validation_data, f, indent=2)

    print("AWS validation data written to aws_validation.json")
    return validation_data

if __name__ == "__main__":
    try:
        tf_outputs = get_terraform_outputs()
        validate_resources(tf_outputs)
    except Exception as e:
        print(f"Validation failed: {e}")