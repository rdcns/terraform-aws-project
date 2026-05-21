# AWS / Terraform local commands

Check AWS identity:
``` powershell
aws sts get-caller-identity
```
Returns your User ID, AWS account ID, and ARN.


Check AWS config:
```powershell
aws configure list
```
Output shows that your actual temporary credentials currently come from your aws login session.


See AWS profiles:
```powershell
aws configure list-profiles
```
