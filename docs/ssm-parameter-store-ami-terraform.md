# Using AWS SSM Parameter Store to Get an EC2 AMI in Terraform

## 1. What problem are we solving?

When creating an EC2 instance with Terraform, AWS asks for an **AMI ID**.

An AMI means **Amazon Machine Image**. It is the operating system image used to create the EC2 instance.

Example:

```hcl
ami = "ami-0123456789abcdef0"
```

The problem is that AMI IDs are not universal. They can be different depending on:

- the AWS region
- the operating system
- the architecture
- the version of the image

For example, an Amazon Linux AMI in `us-east-1` may not have the same ID as an Amazon Linux AMI in `eu-west-3`.

So instead of manually looking for an AMI ID in the AWS Console, we can ask AWS to provide the latest valid AMI automatically.

---

## 2. What is AWS SSM Parameter Store?

**SSM Parameter Store** is a service inside AWS Systems Manager that stores values as parameters.

These values can be things like:

- configuration values
- secrets
- version numbers
- AMI IDs

AWS also provides some **public parameters** that anyone can read. One useful public parameter gives us the latest Amazon Linux 2023 AMI.

The parameter we used is:

```text
/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64
```

This parameter points to the latest Amazon Linux 2023 AMI for the selected AWS region.

---

## 3. Important idea

We are **not creating** the parameter ourselves.

AWS already created it.

Terraform only reads it.

So the logic is:

```text
AWS public SSM parameter
        ↓
contains latest Amazon Linux 2023 AMI ID
        ↓
Terraform reads the value
        ↓
EC2 instance uses that AMI
```

---

## 4. Terraform code to read the AMI from SSM Parameter Store

In Terraform, we use a **data source**.

A data source does not create something. It reads existing information.

```hcl
data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
```

This means:

> Terraform, read this existing AWS SSM parameter and get its value.

The value returned will be an AMI ID, for example:

```text
ami-xxxxxxxxxxxxxxxxx
```

---

## 5. Using the parameter value in an EC2 instance

Instead of hardcoding the AMI like this:

```hcl
ami = "ami-0123456789abcdef0"
```

We use the value from the SSM parameter:

```hcl
ami = data.aws_ssm_parameter.amazon_linux_2023.value
```

Full example:

```hcl
resource "aws_instance" "instance_1" {
  ami           = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = "t3.micro"

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              python3 -m http.server 8080 &
              EOF

  tags = {
    Name        = "My EC2 Instance 1"
    Environment = "Dev"
  }
}
```

---

## 6. Very important Terraform syntax rule

Do **not** put the data source reference inside quotes.

---

## 7. Example with provider, data source, and EC2 instances

```hcl
provider "aws" {
  region = "eu-west-3"
}

data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "instance_1" {
  ami           = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = "t3.micro"

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello from instance 1" > index.html
              python3 -m http.server 8080 &
              EOF

  tags = {
    Name        = "My EC2 Instance 1"
    Environment = "Dev"
  }
}

resource "aws_instance" "instance_2" {
  ami           = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type = "t3.micro"

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello from instance 2" > index.html
              python3 -m http.server 8080 &
              EOF

  tags = {
    Name        = "My EC2 Instance 2"
    Environment = "Dev"
  }
}
```

---

## 8. How to display the AMI ID Terraform found

You can add an output:

```hcl
output "amazon_linux_2023_ami_id" {
  value = data.aws_ssm_parameter.amazon_linux_2023.value
}
```

After running:

```bash
terraform apply
```

Terraform will print the AMI ID it used.

Example output:

```text
amazon_linux_2023_ami_id = "ami-xxxxxxxxxxxxxxxxx"
```

---

## 9. Why this is better than hardcoding an AMI

Using SSM Parameter Store is better because:

- you do not need to search manually in the AWS Console
- Terraform automatically gets a valid AMI for your region
- the code is more reusable
- the code is cleaner
- it avoids errors caused by outdated AMI IDs

---

## 10. Simple summary

SSM Parameter Store is used here to avoid hardcoding an AMI ID.

Terraform reads a public AWS parameter that contains the latest Amazon Linux 2023 AMI ID.

Then the EC2 instance uses that value as its `ami`.

In one sentence:

> We use AWS SSM Parameter Store so Terraform can automatically find the correct Amazon Linux AMI instead of manually writing an AMI ID.
