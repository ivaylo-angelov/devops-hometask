# DEVOPS exercise statement 1

## Solution
For this solution I used python and fastapi to create the backend with 2 endpoints. Both the helm chart and docker image are created and pushed to repositories using github actions. The backend uses an actual real API(https://coinmarketcap.com/api/) to get random data and then populate it in a postgresql db. Below you will find some technical details and notes:

- As a learning experience, I decided to try and use HashiCorp Vault and the Vault Secrets Operator for secrets. See: https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator
- The helm charts are pushed to a repository using this AWS pattern: https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/set-up-a-helm-v3-chart-repository-in-amazon-s3.html I think this is a really neat feature of the helm s3 plugin(https://github.com/hypnoglow/helm-s3)
- I made use of multi-stage builds to further optimize the Dockerfile and have only the necessary dependencies.
- For the db schema, I decided to use a feature of the bitnami helm chart, see values.yaml.
- The helm chart also deploys an ingress resource with the two paths for /populate and /delete.

## Prerequisites
The easist way to test the helm chart is to deploy it on Minikube: https://minikube.sigs.k8s.io/docs/. You will also need to have an API key for coinmarketcap and have Vault running.

You can get a free api key for coinmarketcap from here: https://coinmarketcap.com/api/pricing/ (I promise it doesn't take much 😊)

## Installing vault and creating secrets for the backend:
Most of the instructions are from here: https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator up to 'Deploy and sync a secret' and skipping the app namespace. So you can just follow/copy-paste that guide except for the following steps:

Create a role in Vault to enable access to secret.
```  
vault write auth/demo-auth-mount/role/role1 \
   bound_service_account_names=default \
   bound_service_account_namespaces=default \
   policies=dev \
   audience=vault \
   ttl=24h
```

Create a secret:
```
vault kv put kvv2/webapp/config coinmarketcap_api_key=<your coinmarketcap api key>

```
Set up the Kubernetes authentication for the secret and Create the secret names secretkv in the app namespace:
```
(Use the  templates from this repository)
kubectl apply -f vault/vault-auth-static.yaml
kubectl apply -f vault/static-secret.yaml
```
The end result should be to have a secret called 'secret-kv' in your default k8s namespace with your a coinmarket_api_key in it that contains your api key:
```
kubectl get secret secretkv -o yaml
```
## Deploying the helm chart
Once you have vault running and you have verified that the secret exists, you can install the helm chart:

```
helm repo add example-bucket-http https://devops-task-charts.s3.eu-west-2.amazonaws.com/
helm repo update
helm upgrade -i my-release example-bucket-http/my-backend-app --set postgresql.auth.password=testpass
```
Note: I wanted to avoid having any credentials in values.yaml(even test ones) so used '--set postgresql.auth.password=testpass' here for that. In a real world use case I would probably use: https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator#setup-dynamic-secrets
