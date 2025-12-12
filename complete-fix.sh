#!/bin/bash

# Complete fix for Django redirect loop

set -e

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"
CONTAINER_NAME="dadparsir-web"

echo "Applying complete fix for Django redirect loop..."

# Create a completely new production settings file
sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} \
    "cd /tmp/dadpars_deploy && \
     cat > dadpars_site/settings_production.py << 'EOF'
"""
Django production settings for dadpars_site project.
"""

import os
from pathlib import Path
import dj_database_url

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-production-key-change-me')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.environ.get('DEBUG', '0') == '1'

# Allow hosts from environment or default to localhost
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'main',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'dadpars_site.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'dadpars_site.wsgi.application'

# Database
DATABASES = {
    'default': dj_database_url.config(
        default=os.environ.get('DATABASE_URL', 'sqlite:///' + str(BASE_DIR / 'db.sqlite3'))
    )
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'fa-ir'
TIME_ZONE = 'Asia/Tehran'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [
    BASE_DIR / 'static',
]

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Security settings for production
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# CRITICAL: DISABLE SSL REDIRECT - NGINX HANDLES IT
SECURE_SSL_REDIRECT = False
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Session and CSRF cookies (set to False because nginx handles SSL)
SESSION_COOKIE_SECURE = False
CSRF_COOKIE_SECURE = False
SESSION_COOKIE_HTTPONLY = True
CSRF_COOKIE_HTTPONLY = True

# Allow all hosts in development
if DEBUG:
    ALLOWED_HOSTS = ['*']

# Whitenoise configuration
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
EOF"

# Now recreate the container with the new settings
ssh_commands="
    cd /tmp/dadpars_deploy

    # Stop and remove the container
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    docker rm ${CONTAINER_NAME} 2>/dev/null || true

    # Rebuild the image with new settings
    docker-compose build web

    # Start the container with corrected settings
    docker run -d --name ${CONTAINER_NAME} \\
      --network dadpars_deploy_dadpars_network \\
      -p 8000:8000 \\
      -e DEBUG=0 \\
      -e DATABASE_URL=postgres://dadpars_user:dadpars_password_1403@db:5432/dadpars_db \\
      -e ALLOWED_HOSTS=localhost,127.0.0.1,37.32.13.22,dadpars.ir,www.dadpars.ir \\
      -e SECRET_KEY=django-insecure-production-key-replace-with-real-key \\
      -e DJANGO_SETTINGS_MODULE=dadpars_site.settings_production \\
      -e SECURE_SSL_REDIRECT=False \\
      -e SECURE_PROXY_SSL_HEADER=HTTP_X_FORWARDED_PROTO,https \\
      -v dadpars_deploy_static_volume:/app/staticfiles \\
      -v dadpars_deploy_media_volume:/app/media \\
      --restart unless-stopped \\
      dadpars_deploy-web \\
      gunicorn --bind 0.0.0.0:8000 --workers 3 --timeout 120 --access-logfile - --error-logfile - dadpars_site.wsgi:application

    # Wait for container to be ready
    sleep 15

    # Test without SSL headers first
    echo 'Testing without SSL headers:'
    curl -s -o /dev/null -w 'Status: %{http_code}\n' http://localhost:8000 || echo 'Failed'

    echo ''
    echo 'Testing with SSL headers:'
    curl -H 'X-Forwarded-Proto: https' \\
         -H 'Host: dadpars.ir' \\
         -s -o /dev/null -w 'Status: %{http_code}\n' http://localhost:8000 || echo 'Failed'

    echo ''
    echo 'Container status:'
    docker ps | grep ${CONTAINER_NAME}
"

echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

echo ""
echo "✅ Complete fix applied!"
echo ""
echo "Key changes:"
echo "1. Created a new production settings file with SECURE_SSL_REDIRECT=False"
echo "2. Set SESSION_COOKIE_SECURE=False and CSRF_COOKIE_SECURE=False"
echo "3. Only kept SECURE_PROXY_SSL_HEADER to detect when coming from nginx"
echo ""
echo "The site should now work at https://dadpars.ir without redirect loops"
echo ""
echo "If it still doesn't work, please check nginx error logs with:"
echo "sudo tail -f /var/log/nginx/error.log"
