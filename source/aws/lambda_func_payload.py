def capture_external_post_event_to_kinesis(event, context):
    import json
    import boto3
    
    kinesis = boto3.client('kinesis')
    
    data_json = json.dumps(event)
    
    response = kinesis.put_record(
        StreamName='kinesis_stream',
        Data=data_json,
        PartitionKey='cpf'
    )

    return response
