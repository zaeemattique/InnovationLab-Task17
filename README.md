# Deploying 3-Tier NodeJS Application on AWS EKS with Application Load Balancer (Task 17)

**Zaeem Attique Ashar**  
Cloud Intern

---

## Task Description:

This project involves deploying a 3-tier NodeJS application on AWS Elastic Kubernetes Service (EKS). The infrastructure will be provisioned using Terraform and will include a VPC with public and private subnets across two availability zones, an EKS cluster with managed node groups, and an Application Load Balancer (ALB) for ingress traffic management. The application consists of three tiers: a web frontend, an application backend, and a MySQL database with persistent storage. The AWS Load Balancer Controller will be installed using Helm to automatically provision and manage the ALB based on Kubernetes Ingress resources.

---

## Architecture Diagram:

![alt text](https://raw.githubusercontent.com/zaeemattique/InnovationLab-Task17/refs/heads/main/Task17%20-%20Architecture.drawio.png)
---

## Task 17.1: Create Networking Infrastructure with Terraform

### Terraform Module Structure:
The networking infrastructure is created using the `modules/networking` Terraform module.

### VPC Configuration:
- **VPC CIDR Block:** 10.0.0.0/16
- **DNS Support:** Enabled
- **DNS Hostnames:** Enabled

### Subnet Configuration:

**Public Subnets:**
- Public Subnet A (us-east-1a): 10.0.101.0/24
- Public Subnet B (us-east-1b): 10.0.102.0/24
- Auto-assign Public IP: Enabled
- Tagged for ELB: `kubernetes.io/role/elb = 1`

**Private Subnets:**
- Private Subnet A (us-east-1a): 10.0.1.0/24
- Private Subnet B (us-east-1b): 10.0.2.0/24
- Tagged for Internal ELB: `kubernetes.io/role/internal-elb = 1`

All subnets are tagged with: `kubernetes.io/cluster/Task17-EKS-Cluster-Zaeem = shared`

### Internet Gateway:
- Attached to VPC for public subnet internet access

### NAT Gateway:
- Deployed in Public Subnet A
- Elastic IP allocated for NAT Gateway
- Provides internet access for private subnets

### Route Tables:

**Public Route Table:**
- Route: 0.0.0.0/0 → Internet Gateway
- Associated with both public subnets

**Private Route Table:**
- Route: 0.0.0.0/0 → NAT Gateway
- Associated with both private subnets

---

## Task 17.2: Create IAM Roles for EKS

### EKS Cluster Role:
Created using the `modules/iam` Terraform module.

**Role Name:** Task17-EKS-Cluster-Role-Zaeem

**Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "eks.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
```

**Attached Policy:**
- `arn:aws:iam::aws:policy/AmazonEKSClusterPolicy`

### EKS Node Role:
**Role Name:** Task17-EKS-Node-Role-Zaeem

**Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "ec2.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
```

**Attached Policies:**
- `arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy`
- `arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy`
- `arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly`


---

## Task 17.3: Create EKS Cluster and Node Group

### EKS Cluster Configuration:
Created using the `modules/eks` Terraform module.

**Cluster Name:** Task17-EKS-Cluster-Zaeem  
**Kubernetes Version:** Latest (managed by AWS)  
**Role ARN:** Task17-EKS-Cluster-Role-Zaeem  

**VPC Configuration:**
- All four subnets (2 public + 2 private) attached to cluster

### EKS Node Group Configuration:
**Node Group Name:** Task17-EKS-NodeGroup-Zaeem  
**Node Role ARN:** Task17-EKS-Node-Role-Zaeem  
**Subnets:** Both private subnets (us-east-1a, us-east-1b)  

**Scaling Configuration:**
- Desired Size: 2
- Maximum Size: 3
- Minimum Size: 1

**Instance Configuration:**
- Instance Type: t3.small
- Disk Size: 20 GB
- AMI Type: AL2_x86_64 (Amazon Linux 2)


---

## Task 17.4: Create OIDC Provider for EKS

The OIDC (OpenID Connect) provider enables IAM roles for service accounts (IRSA), allowing Kubernetes service accounts to assume IAM roles.

### OIDC Provider Configuration:
Created using the `modules/eks` Terraform module.

**Data Source:** TLS Certificate from EKS cluster OIDC issuer URL

**Provider Configuration:**
- URL: EKS Cluster OIDC Issuer URL
- Client ID List: `["sts.amazonaws.com"]`
- Thumbprint List: SHA1 fingerprint from TLS certificate

**Dependencies:**
- Waits for cluster to be active using `null_resource`
- TLS certificate data source depends on cluster creation


---

## Task 17.5: Create IAM Role for ALB Controller

### ALB Controller IAM Role:
Created using the `modules/iam_alb` Terraform module.

**Role Name:** Task17-ALB-Controller-Role-Zaeem

**Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "<OIDC_PROVIDER_ARN>"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "<OIDC_PROVIDER>:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller",
        "<OIDC_PROVIDER>:aud": "sts.amazonaws.com"
      }
    }
  }]
}
```

**IAM Policy:**
The ALB Controller requires permissions for:
- Creating/managing Application Load Balancers
- Managing target groups
- Creating/managing security groups
- Managing EC2 resources (subnets, VPCs, ENIs)
- Managing WAF and Shield resources

**Policy Name:** Task17-ALB-Controller-Policy-Zaeem  
**Policy Document:** `iam_policy.json` (AWS Load Balancer Controller IAM policy)


---

## Task 17.6: Configure kubectl and Install EBS CSI Driver

### Configure kubectl:
```powershell
$CLUSTER_NAME = terraform output -raw cluster_name
aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-1
kubectl get nodes
```

### EBS CSI Driver Installation:

The EBS CSI Driver is required for dynamic provisioning of EBS volumes for persistent storage (MySQL database).

**Step 1: Create IAM Policy**
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/docs/example-iam-policy.json" -OutFile "ebs-csi-policy.json"

aws iam create-policy --policy-name AmazonEBSCSIDriverPolicy --policy-document file://ebs-csi-policy.json
```

**Step 2: Create IAM Role for Service Account**
```powershell
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$OIDC_PROVIDER = (terraform output -raw oidc_provider_url) -replace 'https://', ''
```

Trust policy allows the EBS CSI controller service account to assume the role:
- Service Account: `system:serviceaccount:kube-system:ebs-csi-controller-sa`
- Federated Identity: OIDC Provider ARN

**Step 3: Install EBS CSI Driver Addon**
```powershell
aws eks create-addon --cluster-name $CLUSTER_NAME --addon-name aws-ebs-csi-driver --service-account-role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_EBS_CSI_DriverRole
```

**Verification:**
```powershell
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=aws-ebs-csi-driver -n kube-system --timeout=120s
```


---

## Task 17.7: Install AWS Load Balancer Controller using Helm

### Helm Installation:

**Step 1: Add EKS Chart Repository**
```powershell
helm repo add eks https://aws.github.io/eks-charts
helm repo update
```

**Step 2: Install AWS Load Balancer Controller**
```powershell
$CLUSTER_NAME = terraform output -raw cluster_name
$ALB_ROLE_ARN = terraform output -raw alb_controller_iam_role_arn
$VPC_ID = terraform output -raw vpc_id

helm install aws-load-balancer-controller eks/aws-load-balancer-controller `
  -n kube-system `
  --set clusterName=$CLUSTER_NAME `
  --set serviceAccount.create=true `
  --set serviceAccount.name=aws-load-balancer-controller `
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$ALB_ROLE_ARN" `
  --set region=us-east-1 `
  --set vpcId=$VPC_ID
```

**Verification:**
```powershell
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system --timeout=120s
kubectl get deployment -n kube-system aws-load-balancer-controller
```


---

## Task 17.8: Deploy Application Components

### Storage Class Configuration (storageclass.yaml):
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  encrypted: "true"
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

**Key Features:**
- Uses EBS CSI driver (`ebs.csi.aws.com`)
- GP3 volume type (better performance than GP2)
- Encryption enabled
- WaitForFirstConsumer binding mode
- Volume expansion allowed

### Database Tier - MySQL (mysql.yaml):

**Secret Configuration:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: rootpass
  MYSQL_DATABASE: appdb
  MYSQL_USER: appuser
  MYSQL_PASSWORD: apppass
```

**StatefulSet Configuration:**
- **Name:** mysql
- **Replicas:** 1
- **Service Name:** mysql (headless service)
- **Container Image:** mysql:8.0
- **Port:** 3306
- **Volume Mount:** /var/lib/mysql
- **Storage:** 5Gi EBS volume (dynamically provisioned)

**Resource Limits:**
- Memory: 512Mi (request), 1Gi (limit)
- CPU: 250m (request), 500m (limit)

**Health Checks:**
- Liveness Probe: mysqladmin ping
- Readiness Probe: MySQL connection test

**Service Configuration:**
- Type: ClusterIP (Headless)
- Port: 3306
- Selector: app=mysql

### Application Tier - Backend (backend.yaml):

**Deployment Configuration:**
- **Name:** app-backend
- **Replicas:** 2
- **Container Image:** 504649076991.dkr.ecr.us-east-1.amazonaws.com/task17/zaeem:app-tier
- **Port:** 4000

**Environment Variables:**
- DB_HOST: mysql.default.svc.cluster.local
- DB_USER: (from mysql-secret)
- DB_PWD: (from mysql-secret)
- DB_DATABASE: (from mysql-secret)

**Resource Limits:**
- Memory: 256Mi (request), 512Mi (limit)
- CPU: 200m (request), 500m (limit)

**Health Checks:**
- Liveness Probe: HTTP GET /health on port 4000
- Readiness Probe: HTTP GET /health on port 4000

**Service Configuration:**
- **Name:** backend-service
- Type: ClusterIP
- Port: 4000
- Selector: app=backend

### Web Tier - Frontend (frontend.yaml):

**Deployment Configuration:**
- **Name:** web-frontend
- **Replicas:** 2
- **Container Image:** 504649076991.dkr.ecr.us-east-1.amazonaws.com/task17/zaeem:web-tier
- **Port:** 80

**Resource Limits:**
- Memory: 128Mi (request), 256Mi (limit)
- CPU: 100m (request), 300m (limit)

**Health Checks:**
- Liveness Probe: HTTP GET / on port 80
- Readiness Probe: HTTP GET / on port 80

**Service Configuration:**
- **Name:** frontend-service
- Type: NodePort
- Port: 80
- NodePort: 30000
- Selector: app=frontend

**Ingress Configuration:**
- **Name:** frontend-ingress
- **IngressClassName:** alb

**ALB Annotations:**
- `alb.ingress.kubernetes.io/scheme: internet-facing`
- `alb.ingress.kubernetes.io/target-type: instance`
- `alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'`
- `alb.ingress.kubernetes.io/healthcheck-path: /`
- `alb.ingress.kubernetes.io/healthcheck-protocol: HTTP`
- `alb.ingress.kubernetes.io/success-codes: "200"`
- `alb.ingress.kubernetes.io/load-balancer-name: task17-frontend-alb`

**Ingress Rules:**
- Path: /
- Path Type: Prefix
- Backend Service: frontend-service (port 80)

### Deployment Commands:
```powershell
kubectl apply -f storageclass.yaml
kubectl apply -f mysql.yaml
kubectl apply -f backend.yaml
kubectl apply -f frontend.yaml
```


---

## Task 17.9: Testing and Verification

### Verify Node Status:
```powershell
kubectl get nodes
```
Expected output: 2 nodes in Ready state


### Verify Pod Status:
```powershell
kubectl get pods -o wide
```
Expected output:
- 1 MySQL pod running
- 2 Backend pods running
- 2 Frontend pods running


### Verify Services:
```powershell
kubectl get svc
```
Expected output:
- mysql (ClusterIP, port 3306)
- backend-service (ClusterIP, port 4000)
- frontend-service (NodePort, port 80:30000)


### Verify Ingress and ALB:
```powershell
kubectl get ingress frontend-ingress
```
Expected output: Ingress with ALB DNS name in ADDRESS column


### Verify Persistent Volume Claims:
```powershell
kubectl get pvc
```
Expected output: mysql-storage-mysql-0 in Bound state with 5Gi GP3 volume


### Check ALB Controller Logs:
```powershell
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```
Look for successful ALB creation logs


### Verify ALB in AWS Console:
Navigate to EC2 → Load Balancers
- Load Balancer Name: task17-frontend-alb
- State: Active
- Scheme: internet-facing
- Availability Zones: us-east-1a, us-east-1b


### Verify Target Groups:
Navigate to EC2 → Target Groups
- Targets should show 2 EKS worker nodes
- Health Status: Healthy


### Access Application:
```powershell
$ALB_URL = kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
Write-Host "Application URL: http://$ALB_URL"
```

Open the URL in a web browser to access the application on port 80.


### Application Flow Testing:
1. Frontend loads successfully
2. Frontend communicates with backend API
3. Backend connects to MySQL database
4. Data persists across pod restarts


---

## Task 17.10: Lessons Learned

### Infrastructure as Code (IaC):
- Terraform provides consistent and repeatable infrastructure deployment
- Modular structure makes code reusable and maintainable
- Proper dependency management is crucial (using `depends_on`)
- Terraform outputs are essential for passing values between modules and to external tools

### EKS and Kubernetes:
- EKS simplifies Kubernetes cluster management compared to self-managed clusters
- Managed node groups handle node lifecycle automatically
- OIDC provider is essential for IAM roles for service accounts (IRSA)
- Proper subnet tagging is critical for AWS Load Balancer Controller to function

### Networking:
- NAT Gateway is required for private subnets to access internet (for pulling images)
- Public subnets must be tagged with `kubernetes.io/role/elb` for ALB
- Private subnets must be tagged with `kubernetes.io/role/internal-elb` for internal load balancers
- Security groups are managed automatically by EKS and ALB Controller

### Storage:
- EBS CSI Driver is mandatory for dynamic volume provisioning in EKS
- GP3 volumes offer better performance and cost efficiency than GP2
- `WaitForFirstConsumer` binding mode ensures volumes are created in the correct AZ
- StatefulSets with volume claim templates provide stable storage for databases

### AWS Load Balancer Controller:
- Helm is the recommended installation method
- Service account must be annotated with IAM role ARN
- ALB provisioning takes 2-3 minutes after Ingress creation
- Target type `instance` works with NodePort services
- Health check configuration in Ingress annotations is important

