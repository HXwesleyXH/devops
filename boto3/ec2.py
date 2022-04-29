import boto3

# Update credentials in ~/.aws/credentials before use

# Set a especific AZ
region = input("Insira a região que deseja: ")

# Set resource and region
EC2_RESOURCE = boto3.resource('ec2', region_name=region)

# Set resource in var
instances = EC2_RESOURCE.instances.all()

print("-" * 24, region, "-" * 25)

# Show all instances in account
# for instance in instances:
#     print('-' * 21, "EC2 INFORMATION", '-' * 22)
#     print(f'EC2 instance {instance.id}')
#     print(f'Instance state: {instance.state["Name"]}')
#     print(f'Instance AMI: {instance.image.id}')
#     print(f'Key Name: {instance.key_name}')
#     print(f'Instance platform: {instance.platform}')
#     print(f'Instance type: {instance.instance_type}')
#     print(f'Metadata Token: {instance.metadata_options["HttpTokens"]}')
#     print('-' * 26, "NETWORK", '-' * 25)
#     print(f'Public IPv4 address: {instance.public_ip_address}')
#     print(f'Subnet ID: {instance.subnet_id}')
#     print(f'VPC ID: {instance.vpc_id}')
#     print('-' * 60, '\n')


###############################################################################
for instance in instances:
    print(instance.state["Name"])

print('-' * 50)

for instance in instances:
    print(instance.id)

print('-' * 50)

for instance in instances:
    print(instance.key_name)

print('-' * 50)

for instance in instances:
    print(instance.instance_type)

print('-' * 50)

for instance in instances:
    print(instance.public_ip_address)

print('-' * 50)

for instance in instances:
    print(instance.metadata_options["HttpTokens"])

print('-' * 50)
