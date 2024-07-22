# DEVOPS exercise statement 1

## Solution
For this solution I used python and fastapi to create the backend with 2 endpoints. Both the helm chart and docker image are created and pushed to repositories using github actions. The backend uses an actual real API(https://coinmarketcap.com/api/) to get random data and then populate it in a postgresql db. Below you will find some technical details and notes:

- As a learning experience, I decided to try and use HashiCorp Vault and the Vault Secrets Operator for secrets. See: https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator
- The helm charts are pushed to a repository using this AWS pattern: https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/set-up-a-helm-v3-chart-repository-in-amazon-s3.html I think this is a really neat feature of the helm s3 plugin(https://github.com/hypnoglow/helm-s3)
- I made use of multi-stage builds to further optimize the Dockerfile and have only the necessary dependencies.
- For the db schema, I decided to use a feature of the bitnami helm chart, see values.yaml.
- The helm chart also deploys an ingress resource with the two paths for /populate and /delete.

## Prerequisites
The easist way to test the helm chart is to deploy it on Minikube: https://minikube.sigs.k8s.io/docs/. Also have a look at https://minikube.sigs.k8s.io/docs/start/?arch=%2Fmacos%2Fx86-64%2Fstable%2Fbinary+download#Ingress to enable ingress. 

Note: You will also need to have an API key for coinmarketcap and have Vault running.
A free api key for coinmarketcap can be obtained from here: https://coinmarketcap.com/api/pricing/ (I promise it doesn't take much time 😊)

## Installing vault and creating secrets for the backend:
Most of the instructions are from here: https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator up to and including 'Deploy and sync a secret' and skipping the app namespace creation. So you can just follow/copy-paste that guide except for the following steps:

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

## Testing the application

After the helm chart is deployed and all the pods are running, you can use the the ingress resource's address to create some requests using curl or postman:

```
curl --location --request POST 'localhost/populate''

curl --location --request DELETE 'localhost/delete'
```

Using kube-proxy and the included pg-admin ui, the db changes can be reviewed.

## Caveats and considerations

- There is actually a small bug when deploying for the first time, because the application tries to connect to the database and it fails before postgres is ready. So the backend pod crashes and restarts for a once or twice before it's running.

## DEVOPS exercise statement 2

This exercise also uses Coinmarketcap's api to get random data. The lambda function will then create a random file in s3 every time it gets invoked.

Notes:
- I'm using remote s3 state for terraform and dynamodb locks. See backend.tf
- The Coinmarketcap API key is stored in github actions as secret and then created with terraform as secret in Secrets Manager. Lambda then picks it up using the secrets manager api.
- In Account A(the account where this repository is deploying the resources) an IAM role is created with terraform that allows lambda to put objects in the s3 bucket in Account B(where the s3 bucket is). An s3 bucket policy allows only the lambda role in Account A to put objects(cross account policy).
- I picked libraries for the lambda function that already come with the runtime to avoid having another build step(e.g. requests isn't included, but urllib is)

## Testing

You can use curl or postman to invoke the lambda function using API Gateway: 

``
curl --location --request POST 'https://gplgx3tdee.execute-api.eu-west-2.amazonaws.com/prod/populate'
``

## Caveats

- Main one: For the custom domain I used AWS ACM and imported a self-signed certificate so it's not really usable this way. The API Gateway is also deployed as Regional, because Edge-optimized uses CloudFront underneath(and CF checks if the certificate is issued by a trusted CA). Because Route53 domains are expensive :disappointed_relieved: Note: In a production environment I would issue an ACM certificate using DNS verification and verify it using a real domain in route53(or registry where the domain was purchased). Then create a CNAME record to the API Gateway's custom domain.
- The s3 bucket policy in account B is created manually.
- Most of the terraform resources are created for this specific use-case, but a lot of them can benefit from using modules.
- At the moment, there is no terraform plan review or approval step.
- API Gateway's resource policy is made open by design to allow for easy testing of this solution. A much fine-grained policy should be used in a real environment.
