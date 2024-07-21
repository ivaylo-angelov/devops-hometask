import os
import boto3
import json
import random
import string
import urllib.request

def lambda_handler(event, context):
    secret_name = "coinmarketcap_api_key"
    region_name = "eu-west-2"

    session = boto3.session.Session()
    client = session.client(service_name='secretsmanager', region_name=region_name)

    get_secret_value_response = client.get_secret_value(SecretId=secret_name)
    secret = json.loads(get_secret_value_response['SecretString'])
    api_key = secret['api_key']

    url = os.environ['COINMARKETCAP_URL']
    headers = {
        'Accept': 'application/json',
        'X-CMC_PRO_API_KEY': api_key,
    }

    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())

    random_string = ''.join(random.choices(string.ascii_lowercase + string.digits, k=10))
    file_content = json.dumps(data, indent=4)

    s3_client = boto3.client('s3')
    bucket_name = os.environ['BUCKET_NAME']
    s3_client.put_object(Bucket=bucket_name, Key=f'{random_string}.json', Body=file_content)

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Data uploaded successfully'})
    }