import json
import boto3

def capture_external_post_event_to_kinesis(event, context):
    kinesis = boto3.client('kinesis')
    
    data_json = json.dumps(event)
    
    try:
        response = kinesis.put_record(
            StreamName='kinesis_stream',
            Data=data_json,
            PartitionKey='cpf'
        )
        
        status_code = response['ResponseMetadata']['HTTPStatusCode']
        message = 'Registro enviado com sucesso'
    except Exception as e:
        status_code = 500  # Código de erro interno do servidor
        message = str(e)
    
    return {
        'statusCode': status_code,
        'headers': { 'Content-Type': 'application/json' },
        'body': json.dumps(message)
    }

