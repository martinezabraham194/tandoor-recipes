# Tandoor Recipes Deployment Guide

<!-- filepath: README.md -->

This guide provides step-by-step instructions for deploying Tandoor Recipes to Google Cloud Run with a Supabase PostgreSQL database.

## Prerequisites

- Google Cloud Platform account with billing enabled
- Supabase account with a PostgreSQL database
- Docker installed locally
- Google Cloud CLI (`gcloud`) installed and configured

## Database Setup

1. Create a PostgreSQL database in Supabase
2. Note the connection information:
   - Host: `aws-0-us-east-1.pooler.supabase.com`
   - Port: `5432`
   - Database: `postgres`
   - Username: `postgres.rhrjaxnzwuuxfgijzqxz`
   - Password: `your-database-password`

## Environment Configuration

1. Create an env_vars.yaml file with the following content:

```yaml
# allowed hosts
ALLOWED_HOSTS: "*.run.app,tandoor-59868711850.us-east4.run.app,localhost"

# database connection
DATABASE_URL: "postgresql://postgres.rhrjaxnzwuuxfgijzqxz:your-database-password@aws-0-us-east-1.pooler.supabase.com:5432/postgres?sslmode=require"

# connection stability
CONN_MAX_AGE: "60"
POSTGRES_OPTIONS: '{"sslmode":"require", "keepalives":1, "keepalives_idle":30, "keepalives_interval":10, "keepalives_count":5}'
DB_TIMEOUT: "180"

# social authentication settings
SOCIAL_PROVIDERS: "allauth.socialaccount.providers.google"
AUTHENTICATION_BACKENDS: "django.contrib.auth.backends.ModelBackend,allauth.account.auth_backends.AuthenticationBackend"
SITE_ID: "1"
ACCOUNT_EMAIL_VERIFICATION: "none"
ENABLE_SIGNUP: "1"
LOGIN_REDIRECT_URL: "/"
ACCOUNT_ALLOW_REGISTRATION: "True"
SOCIALACCOUNT_AUTO_SIGNUP: "True"
SOCIALACCOUNT_PROVIDERS: '{"google": {"SCOPE": ["profile", "email"], "AUTH_PARAMS": {"access_type": "online"}}}'

# debugging (remove in production)
DEBUG: "1"

# email settings
EMAIL_HOST: "smtp.gmail.com"
EMAIL_PORT: "587"
EMAIL_USE_TLS: "1"
EMAIL_HOST_USER: "your-email@gmail.com"
EMAIL_HOST_PASSWORD: "your-app-password"
DEFAULT_FROM_EMAIL: "your-email@gmail.com"
```

## Dockerfile

Create a Dockerfile with the following content:

```dockerfile
FROM ghcr.io/tandoorrecipes/recipes:master

# Install additional dependencies
RUN pip install firebase-admin==6.5.0 supabase==2.7.4

# Install additional dependencies including bash and curl
RUN apk add --no-cache bash curl jq postgresql-client ca-certificates

# Create the mediafiles directory
RUN mkdir -p /opt/recipes/mediafiles && chmod 755 /opt/recipes/mediafiles

# Permanently patch the settings.py file to handle Supabase usernames with periods
RUN sed -i 's/\((?P<user>\[\\w\\d_-\]+\)/\((?P<user>\[\\w\\d_.-\]+\)/g' /opt/recipes/recipes/settings.py

# Set Gunicorn parameters
ENV GUNICORN_CMD_ARGS="--workers=1 --threads=4"
```

## Deployment Script

Create a deploy.bat script with the following content:

```bat
@echo off
REM filepath: c:\Users\Abe-Dev\Documents\Github\tandoor-recipes\deploy.bat

echo === Building Docker Image ===
docker build -t tandoor-local .

echo === Tagging Docker Image ===
docker tag tandoor-local us-east4-docker.pkg.dev/tandoor-recipes-40b2a/tandoor-repo/tandoor:latest

echo === Pushing Docker Image to Google Container Registry ===
docker push us-east4-docker.pkg.dev/tandoor-recipes-40b2a/tandoor-repo/tandoor:latest

echo === Deploying Main Service to Google Cloud Run ===
gcloud run deploy tandoor ^
  --image us-east4-docker.pkg.dev/tandoor-recipes-40b2a/tandoor-repo/tandoor:latest ^
  --region us-east4 ^
  --allow-unauthenticated ^
  --port 8080 ^
  --env-vars-file env_vars.yaml ^
  --cpu 1 ^
  --memory 1024Mi ^
  --min-instances 1 ^
  --max-instances 10 ^
  --timeout 300 ^
  --platform managed

echo === Deployment Complete ===
echo Your application should be available at the URL shown above.
```

## Deployment Steps

1. **Configure Google Cloud:**
   ```bash
   gcloud auth login
   gcloud config set project tandoor-recipes-40b2a
   ```

2. **Create Google Cloud Artifact Registry:**
   ```bash
   gcloud artifacts repositories create tandoor-repo --repository-format=docker --location=us-east4
   ```

3. **Configure Docker for Google Cloud:**
   ```bash
   gcloud auth configure-docker us-east4-docker.pkg.dev
   ```

4. **Deploy Tandoor Recipes:**
   ```bash
   deploy.bat
   ```

5. **Set Up Google OAuth:**
   - Go to Google Cloud Console → APIs & Services → Credentials
   - Create an OAuth 2.0 Client ID for Web Application
   - Set Authorized JavaScript Origins: `https://tandoor-59868711850.us-east4.run.app`
   - Set Authorized Redirect URIs: `https://tandoor-59868711850.us-east4.run.app/accounts/google/login/callback/`
   - Copy Client ID and Secret
   - Access your deployed Tandoor admin page
   - Go to Sites → Add a new site with domain `tandoor-59868711850.us-east4.run.app`
   - Go to Social Applications → Add a Google provider with your Client ID and Secret
   - Add your site to the chosen sites

6. **Set Up Email for Invitations:**
   - Create an App Password in your Google Account Security settings
   - Update env_vars.yaml with your email settings
   - Redeploy the application

## Troubleshooting

If you encounter issues:

1. **Database Connection Errors:**
   - Verify Supabase connection parameters
   - Check that the regex patch is applied correctly

2. **Social Login Button Missing:**
   - Verify Site ID in admin interface
   - Check OAuth configuration in Google Cloud Console
   - Ensure the social app is associated with your site

3. **Email Sending Fails:**
   - Verify app password is correct
   - Check email configuration in env_vars.yaml
   - Test with debug mode enabled

## Maintenance

To update your deployment:

1. Make changes to your configuration files
2. Run deploy.bat to rebuild and redeploy the application

Enjoy your self-hosted Tandoor Recipes installation!