import requests
import json
from fakedadosbr import fake_cidadao

# from dotenv import load_dotenv
# load_dotenv()
# import os
# api_key = os.getenv('API_KEY')
# database_uri = os.getenv('DATABASE_URI')

url = "https://dmocc01b14.execute-api.us-east-1.amazonaws.com/dev"

headers = {
    "Content-Type": "application/json"
}

keys_to_remove = ["idade", "sexo", "rg", "signo", "mae", "pai", "senha", "telefone_fixo", "celular", "altura", "peso", "tipo_sanguineo", "cor"]

qtd_msg = 39

cidadaos = fake_cidadao(30)

for cidadao in cidadaos:
    qtd_msg += 1
    data = cidadao
    data['id'] = qtd_msg
    for key in keys_to_remove:
        if key in data:
            del data[key]

    response = requests.post(url, headers=headers, data=json.dumps(data))

    if response.status_code == 200:
        print("Enviado ID: ", qtd_msg)
    else:
        print(f"Erro ao enviar a solicitação: {response.status_code}")
        break

