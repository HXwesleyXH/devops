import boto3

# Update credentials in ~/.aws/credentials before use

# Set a especific AZ
region = input("Insira a região que deseja: ")

# Set resource and region
s3 = boto3.resource('s3', region_name=region)

# Set resource in var
buckets = s3.buckets.all()

# List all bucket's in account
for bucket in buckets:
    print('-' * 60)
    print(f'Bucket Name: {bucket.name}')
    print(f'creation Date: {bucket.creation_date}')
    print('-' * 60, '\n')



# List a bucket content
# bucket = s3.Bucket('nowonlinecloud-static')  # Add a bucket name in object ''

# List all objects in the specific bucket
# for obj in bucket.objects.all():
#     print(obj.key)
