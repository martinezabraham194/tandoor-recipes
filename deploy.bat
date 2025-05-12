@echo off
REM filepath: c:\Users\Abe-Dev\Documents\Github\tandoor-recipes\deploy.bat

echo === Building Docker Image ===
docker build -t tandoor-local .

echo === Running Database Migrations Locally ===
@REM docker run --rm tandoor-local /bin/sh -c "cd /opt/recipes && source venv/bin/activate && python manage.py migrate"

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