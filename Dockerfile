FROM ghcr.io/tandoorrecipes/recipes:master

# Install additional dependencies
RUN pip install firebase-admin==6.5.0 supabase==2.7.4

# Install additional dependencies including bash and curl for Supabase CLI
RUN apk add --no-cache bash curl jq postgresql-client

# Create the mediafiles directory
RUN mkdir -p /opt/recipes/mediafiles && chmod 755 /opt/recipes/mediafiles

# Permanently patch the settings.py file to handle Supabase usernames with periods
RUN sed -i 's/\((?P<user>\[\\w\\d_-\]+\)/\((?P<user>\[\\w\\d_.-\]+\)/g' /opt/recipes/recipes/settings.py

# Set Gunicorn parameters
ENV GUNICORN_CMD_ARGS="--workers=1 --threads=4"