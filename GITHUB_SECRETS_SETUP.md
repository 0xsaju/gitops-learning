# GitHub Secrets Setup Guide

## 🔐 Required Secrets for Automated Deployment

This guide will help you set up the necessary GitHub Secrets for the automated CI/CD pipeline to work with the modular Terraform infrastructure.

## 📋 Required Secrets

### 1. AWS Credentials
- **AWS_ACCESS_KEY_ID**: Your AWS access key
- **AWS_SECRET_ACCESS_KEY**: Your AWS secret access key

### 2. Docker Hub Credentials
- **DOCKERHUB_USERNAME**: Your Docker Hub username
- **DOCKERHUB_TOKEN**: Your Docker Hub access token

## 🚀 Step-by-Step Setup

### Step 1: Get AWS Credentials

1. **Log into AWS Console**
   - Go to [AWS Console](https://console.aws.amazon.com/)
   - Navigate to IAM → Users → Your User

2. **Create Access Keys**
   - Click on "Security credentials" tab
   - Click "Create access key"
   - Choose "Application running outside AWS"
   - Download the CSV file with your credentials

3. **Required AWS Permissions**
   Your AWS user needs these permissions:
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "ec2:*",
                   "vpc:*",
                   "iam:*",
                   "elasticloadbalancing:*",
                   "autoscaling:*",
                   "rds:*",
                   "s3:*",
                   "cloudwatch:*",
                   "logs:*"
               ],
               "Resource": "*"
           }
       ]
   }
   ```

### Step 2: Get Docker Hub Credentials

1. **Log into Docker Hub**
   - Go to [Docker Hub](https://hub.docker.com/)
   - Sign in to your account

2. **Create Access Token**
   - Go to Account Settings → Security
   - Click "New Access Token"
   - Give it a name (e.g., "GitHub Actions")
   - Copy the token (you won't see it again!)

3. **Note Your Username**
   - Your Docker Hub username is visible in your profile

### Step 3: Add Secrets to GitHub Repository

1. **Go to Your GitHub Repository**
   - Navigate to your repository on GitHub
   - Click on "Settings" tab

2. **Navigate to Secrets**
   - Click on "Secrets and variables" in the left sidebar
   - Click on "Actions"

3. **Add Each Secret**
   Click "New repository secret" and add:

   **AWS_ACCESS_KEY_ID**
   - Name: `AWS_ACCESS_KEY_ID`
   - Value: Your AWS access key (from Step 1)

   **AWS_SECRET_ACCESS_KEY**
   - Name: `AWS_SECRET_ACCESS_KEY`
   - Value: Your AWS secret access key (from Step 1)

   **DOCKERHUB_USERNAME**
   - Name: `DOCKERHUB_USERNAME`
   - Value: Your Docker Hub username (from Step 2)

   **DOCKERHUB_TOKEN**
   - Name: `DOCKERHUB_TOKEN`
   - Value: Your Docker Hub access token (from Step 2)

## 🔍 Verification Steps

### Step 1: Test AWS Credentials
```bash
# Test AWS CLI configuration
aws configure list
aws sts get-caller-identity
```

### Step 2: Test Docker Hub Login
```bash
# Test Docker Hub login
docker login -u YOUR_DOCKERHUB_USERNAME
# Enter your token when prompted for password
```

### Step 3: Test GitHub Actions
1. **Create a test branch**:
   ```bash
   git checkout -b test-secrets
   git push origin test-secrets
   ```

2. **Check GitHub Actions**:
   - Go to your repository → Actions tab
   - Verify the workflow runs without errors

## 🛠️ Troubleshooting

### Common Issues

1. **AWS Credentials Error**
   - Verify access key and secret are correct
   - Check IAM permissions
   - Ensure region is set correctly

2. **Docker Hub Authentication Error**
   - Verify username and token are correct
   - Check if token has proper permissions
   - Ensure token hasn't expired

3. **GitHub Actions Failing**
   - Check secret names match exactly
   - Verify secrets are added to the correct repository
   - Check workflow file syntax

### Debug Commands

```bash
# Test AWS credentials
aws sts get-caller-identity

# Test Docker Hub
docker login -u YOUR_USERNAME

# Check GitHub CLI (if installed)
gh auth status
```

## 🔒 Security Best Practices

1. **Use IAM Roles** (if possible)
   - Create specific IAM roles for GitHub Actions
   - Use OIDC instead of access keys

2. **Rotate Credentials Regularly**
   - Update AWS access keys every 90 days
   - Rotate Docker Hub tokens periodically

3. **Principle of Least Privilege**
   - Grant minimum required permissions
   - Use specific resource ARNs when possible

4. **Monitor Usage**
   - Enable CloudTrail for AWS API calls
   - Monitor Docker Hub usage

## 📝 Example Workflow Test

After setting up secrets, test with a simple workflow:

```yaml
name: Test Secrets
on: [push]
jobs:
  test-aws:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-southeast-1
      
      - name: Test AWS
        run: aws sts get-caller-identity
  
  test-docker:
    runs-on: ubuntu-latest
    steps:
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      
      - name: Test Docker
        run: docker pull hello-world
```

## ✅ Success Criteria

Your setup is successful when:

1. ✅ All secrets are added to GitHub repository
2. ✅ AWS credentials work with CLI
3. ✅ Docker Hub login works
4. ✅ GitHub Actions workflow runs without errors
5. ✅ Infrastructure deploys successfully

## 🚀 Next Steps

After setting up secrets:

1. **Test Staging Deployment**:
   ```bash
   git checkout -b staging
   git push origin staging
   ```

2. **Monitor Deployment**:
   - Check GitHub Actions tab
   - Verify infrastructure creation
   - Test application endpoints

3. **Deploy to Production**:
   ```bash
   git checkout -b production
   git push origin production
   ```

## 📞 Support

If you encounter issues:

1. Check this documentation
2. Verify all secrets are correctly set
3. Test credentials manually
4. Check GitHub Actions logs for specific errors
5. Contact DevOps team for assistance 