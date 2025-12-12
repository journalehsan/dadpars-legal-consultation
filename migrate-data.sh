#!/bin/bash

# Script to migrate data from local SQLite to PostgreSQL server

set -e

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"
CONTAINER_NAME="dadparsir-web"

echo "Migrating data from local SQLite to PostgreSQL server..."
echo ""

# First, let's check if the data file exists and has content
if [ ! -f "local_data.json" ]; then
    echo "❌ Error: local_data.json not found!"
    exit 1
fi

echo "✅ Found local_data.json with $(wc -l < local_data.json) lines"

# Transfer the data file to the server
echo "Transferring data to server..."
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no local_data.json ${SERVER_USER}@${SERVER_IP}:/tmp/

# Run the migration on the server
echo ""
echo "Running migration on server..."
ssh_commands="
    # Copy data to container
    docker cp /tmp/local_data.json ${CONTAINER_NAME}:/app/

    # Clear existing data (optional - remove if you want to keep existing data)
    echo 'Clearing existing data...'
    docker exec ${CONTAINER_NAME} python manage.py shell << 'PYTHON_EOF'
from main.models import Service, ConsultationType, FAQ, RecentQuestion, SiteContent

# Delete existing data
Service.objects.all().delete()
ConsultationType.objects.all().delete()
FAQ.objects.all().delete()
RecentQuestion.objects.all().delete()
SiteContent.objects.all().delete()

print('Cleared existing data')
PYTHON_EOF

    # Load the new data
    echo 'Loading new data...'
    docker exec ${CONTAINER_NAME} python manage.py loaddata /app/local_data.json

    # Verify the data was loaded
    echo ''
    echo 'Verifying data migration:'
    docker exec ${CONTAINER_NAME} python manage.py shell << 'PYTHON_EOF'
from main.models import Service, ConsultationType, FAQ, RecentQuestion

print(f'Services: {Service.objects.count()}')
print(f'Consultation Types: {ConsultationType.objects.count()}')
print(f'FAQs: {FAQ.objects.count()}')
print(f'Recent Questions: {RecentQuestion.objects.count()}')

# Show first service as sample
if Service.objects.exists():
    s = Service.objects.first()
    print(f'\\nFirst Service: {s.title}')
    print(f'Description: {s.description[:100]}...')
PYTHON_EOF

    # Clean up
    rm -f /tmp/local_data.json
    docker exec ${CONTAINER_NAME} rm -f /app/local_data.json
"

echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

echo ""
echo "✅ Data migration completed!"
echo ""
echo "Your services, consultation types, FAQs, and recent questions have been migrated to the server."
echo "You can now check them at https://dadpars.ir"
