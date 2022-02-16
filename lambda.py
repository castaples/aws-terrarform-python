import json
import boto3
from exif import Image
import os

s3_client = boto3.client("s3")

def remove_exif(image_file):
    image = Image(image_file)
    if image.has_exif:
        image.delete_all()
    return image.get_file()

def lambda_handler(event, context):
    destination_bucket = os.environ.get('DST_BUCKET')
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    key_name = event['Records'][0]['s3']['object']['key']

    try:
        image_file = s3_client.get_object(Bucket=source_bucket, Key=key_name)['Body'].read()
    except Exception as e:
        print(e)
        print(f'Error getting object {key_name} from bucket {source_bucket}.')
        raise e

    image = remove_exif(image_file)

    try:
        s3_client.put_object(Bucket=destination_bucket, Key=key_name, Body=image)
    except Exception as e:
        print(e)
        print(f'Error putting object {key_name} into bucket {destination_bucket}.')
        raise e

    return {
        'statusCode': 200,
        'body': json.dumps('Success!')
    }