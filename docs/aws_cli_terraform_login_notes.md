# AWS CLI Login + Terraform Profile Setup

## Goal

Use Terraform securely from VS Code without storing permanent AWS access keys in the project.

Instead of writing access keys in files, we use:

```text
AWS CLI login session
→ temporary credentials
→ Terraform uses them through a profile
```

---

## Problem I had

I authenticated with:

```powershell
aws login
```

And this command worked:

```powershell
aws sts get-caller-identity
```

It returned my AWS user/account/ARN, so AWS CLI knew who I was.

But Terraform gave this error:

```text
Error: No valid credential sources found
failed to refresh cached credentials
no EC2 IMDS role found
```

Meaning:

> Terraform could not find AWS credentials to access the S3 backend.

Terraform then tried to get credentials from EC2 metadata, but I was running Terraform locally in VS Code, not inside an EC2 instance.

---

## Why Terraform needs credentials

Terraform needs AWS credentials for two things:

### 1. Backend access

The S3 backend stores the Terraform state file.

Example:

```hcl
backend "s3" {
  bucket         = "cia-project-bucket"
  key            = "cia-project/dev/terraform.tfstate"
  region         = "eu-west-3"
  dynamodb_table = "terraform-state-locking"
  encrypt        = true
}
```

Terraform needs permissions to read/write the state file in S3.

### 2. Provider access

The AWS provider creates, updates, and deletes AWS resources.

Example:

```hcl
provider "aws" {
  region = "eu-west-3"
}
```

Terraform needs AWS credentials to manage resources like S3, EC2, DynamoDB, etc.

---

## Secure idea

Do not store permanent access keys like this:

```ini
aws_access_key_id = ...
aws_secret_access_key = ...
```

Instead, use temporary credentials from AWS CLI login.

---

## The dev-login solution

### Step 1 — Create a real AWS login profile

Run:

```powershell
aws login --profile dev-login
```

This opens the browser and logs into AWS under a local AWS CLI profile called `dev-login`.

`dev-login` is just a profile name. It is not a webpage.

You could call it something else, but here we use:

```text
dev-login = real AWS login session
```

---

### Step 2 — Test the real login profile

Run:

```powershell
aws sts get-caller-identity --profile dev-login
```

This asks AWS:

> Who am I when I use the `dev-login` profile?

If it returns the User ID, Account ID, and ARN, the login works.

---

### Step 3 — Open the AWS CLI config file

Run:

```powershell
notepad $env:USERPROFILE\.aws\config
```

This opens the local AWS CLI configuration file on Windows.

This file stores AWS CLI settings like:

- profile names
- region
- output format
- credential process commands

It does not need to store permanent secret keys.

---

### Step 4 — Add the profiles

Add this to the config file:

```ini
[profile dev-login]
region = eu-west-3

[profile terraform-login]
region = eu-west-3
credential_process = aws configure export-credentials --profile dev-login --format process
```

Then save the file.

---

## What each profile means

### dev-login

```ini
[profile dev-login]
region = eu-west-3
```

This is the real AWS login profile.

It represents:

```text
my AWS browser login session for local development
```

### terraform-login

```ini
[profile terraform-login]
region = eu-west-3
credential_process = aws configure export-credentials --profile dev-login --format process
```

This is the Terraform bridge profile.

It tells Terraform:

> When you need AWS credentials, ask AWS CLI to export temporary credentials from `dev-login`.

So `terraform-login` does not store permanent secrets.

It only stores a command that fetches temporary credentials.

---

## Why this works

Terraform needs credentials in a format it can read.

This setup creates a bridge:

```text
Terraform
→ terraform-login profile
→ credential_process command
→ AWS CLI dev-login session
→ temporary AWS credentials
→ access to S3 backend and AWS resources
```

The important line is:

```ini
credential_process = aws configure export-credentials --profile dev-login --format process
```

It means:

> Use AWS CLI to take the active login from `dev-login` and export temporary credentials in a format Terraform understands.

---

## Step 5 — Test the Terraform profile

Run:

```powershell
aws sts get-caller-identity --profile terraform-login
```

This checks if `terraform-login` can successfully get credentials from `dev-login`.

If it returns the User ID, Account ID, and ARN, Terraform should be able to use it.

---

## Step 6 — Use it with Terraform

In the same PowerShell terminal, run:

```powershell
$env:AWS_PROFILE="terraform-login"
terraform init -reconfigure
terraform plan
```

This tells Terraform:

> Use the `terraform-login` AWS profile for this terminal session.

---

## Optional Terraform config

You can either set the profile in the terminal:

```powershell
$env:AWS_PROFILE="terraform-login"
```

Or put it directly in Terraform:

```hcl
backend "s3" {
  bucket         = "cia-project-bucket"
  key            = "cia-project/dev/terraform.tfstate"
  region         = "eu-west-3"
  dynamodb_table = "terraform-state-locking"
  encrypt        = true
  profile        = "terraform-login"
}

provider "aws" {
  region  = "eu-west-3"
  profile = "terraform-login"
}
```

The terminal method is cleaner because it keeps the Terraform files more portable.

---

## Important commands

### See AWS profiles

```powershell
aws configure list-profiles
```

### See current AWS CLI configuration

```powershell
aws configure list
```

### Check who I am

```powershell
aws sts get-caller-identity
```

### Check a specific profile

```powershell
aws sts get-caller-identity --profile dev-login
aws sts get-caller-identity --profile terraform-login
```

### Set Terraform profile for current terminal

```powershell
$env:AWS_PROFILE="terraform-login"
```

### Reinitialize Terraform backend

```powershell
terraform init -reconfigure
```

### Preview Terraform changes

```powershell
terraform plan
```

### Apply Terraform changes

```powershell
terraform apply
```

---

## Why this is more secure

This setup is safer because:

- no permanent access keys are stored in the Terraform project;
- no secret keys are pushed to GitHub;
- Terraform receives temporary credentials;
- the real login is handled by AWS CLI;
- the profile only stores a command, not a secret.

Simple summary:

```text
Access keys = long-term secrets
AWS login + credential_process = temporary credentials
```

---

## Important notes about my Terraform backend

The backend bucket and DynamoDB table must already exist before Terraform can use them as a backend.

Also, the DynamoDB table name in the backend must match the real table name.

Example:

```hcl
dynamodb_table = "terraform-state-locking"
```

If the real DynamoDB table is named `terraform-state-locking`, do not write:

```hcl
dynamodb_table = "terraform_locks"
```

because that is a different name.

---

## Simple final explanation

This setup works because:

```text
dev-login = my real AWS login session
terraform-login = the profile Terraform uses
credential_process = the command that gives Terraform temporary credentials
```

So Terraform can securely authenticate to AWS without me writing permanent AWS keys in my project.
