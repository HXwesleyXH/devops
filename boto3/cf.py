import boto3

# Set environments
profile = input("Insira o perfil que deseja: ")
region = input("Insira a região que deseja: ")

# Create CloudFront client
session = boto3.Session(region_name=region, profile_name=profile)
cf = session.client('cloudfront')

# List distributions
distributions = cf.list_distributions()

if distributions['DistributionList']['Quantity'] > 0:
    for distribution in distributions['DistributionList']['Items']:
        print('-' * 60)
        print(f'ID: {distribution["Id"]}')
        print(f'Domain: {distribution["DomainName"]}')
        print(f'Comment: {distribution["Comment"]}')
        print('-' * 60, '\n')
