def lambda_handler(event, context):
    import json
    import boto3
    
    kinesis = boto3.client('kinesis')
    
    data_json = json.dumps(event)
    
    response = kinesis.put_record(
        StreamName='eventbridge_kinesis_data_stream',
        Data=data_json,
        PartitionKey='cpf'
    )

    return response
