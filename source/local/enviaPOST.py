import requests
import json
from fakedadosbr import fake_cidadao
import subprocess

# from dotenv import load_dotenv
# load_dotenv()
# import os
# api_key = os.getenv('API_KEY')
# database_uri = os.getenv('DATABASE_URI')

def get_invoke_url() -> str:
    """ Faz uma requisição ao Terraform pelo output 'invoke_url'
        para obter a URL do API Gateway

        Entrada: -
        Saídda: (str) URL
    """
    result = subprocess.run(["terraform", "output", "invoke_url"], capture_output=True, text=True)
    if result.returncode == 0:
        return result.stdout.strip('\n').strip('"')
    else:
        raise Exception("Error getting invoke_url: " + result.stderr)

def send_post(url:str) -> None:
  """ Envia uma requisição POST à url informada
      Entrada: (str) url
      Saída: None
  """
  headers = {
      "Content-Type": "application/json"
  }

  # A biblioteca fakedadosbr gera informações que, para este exemplo, se fazem desnecessários.
  # Assim, informa as colunas que não usaremos
  keys_to_remove = ["idade", "sexo", "rg", "signo", "mae", "pai", "senha", "telefone_fixo", "celular", "altura", "peso", "tipo_sanguineo", "cor"]
  # Quantidade de fakes gerados. Máx. 30
  QTD = 1
  # Dados de cidadãos fake
  cidadaos = fake_cidadao(QTD)
  # remove algumas colunas e acresenta um ID para cada cidadao
  for idx, cidadao in enumerate(cidadaos):
      data = cidadao
      for key in keys_to_remove:
          if key in data:
              del data[key]
      data['id'] = idx

      response = requests.post(url, headers=headers, data=json.dumps(data))

      if response.status_code == 200:
          print("Enviado ID: ", idx)
      else:
          print(f"Erro ao enviar a solicitação: {response.status_code}")
          break

if __name__ == "__main__":
  invoke_url = get_invoke_url()
  send_post(invoke_url)
