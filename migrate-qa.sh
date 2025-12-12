#!/bin/bash

# Script to migrate Questions and Answers from local SQLite to PostgreSQL server

set -e

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"
CONTAINER_NAME="dadparsir-web"

echo "Migrating Questions and Answers from local SQLite to PostgreSQL server..."
echo ""

# First, let's check if the data file exists and has content
if [ ! -f "qa_data.json" ]; then
    echo "❌ Error: qa_data.json not found!"
    exit 1
fi

echo "✅ Found qa_data.json with $(cat qa_data.json | grep -c '"model":') records"

# Transfer the data file to the server
echo "Transferring data to server..."
sshpass -p "$SERVER_PASSWORD" scp -o StrictHostKeyChecking=no qa_data.json ${SERVER_USER}@${SERVER_IP}:/tmp/

# Run the migration on the server
echo ""
echo "Running migration on server..."
ssh_commands="
    # Copy data to container
    docker cp /tmp/qa_data.json ${CONTAINER_NAME}:/app/

    # Load the new data (this will update existing questions and add answers)
    echo 'Loading Questions and Answers data...'
    docker exec ${CONTAINER_NAME} python manage.py loaddata /app/qa_data.json

    # Verify the data was loaded
    echo ''
    echo 'Verifying QA migration:'
    docker exec ${CONTAINER_NAME} python manage.py shell << 'PYTHON_EOF'
from main.models import RecentQuestion, LawyerAnswer

print(f'Recent Questions: {RecentQuestion.objects.count()}')
print(f'Lawyer Answers: {LawyerAnswer.objects.count()}')

# Show questions with their answers
for q in RecentQuestion.objects.all():
    print(f'\\nQuestion: {q.question[:50]}...')
    answers = LawyerAnswer.objects.filter(question=q)
    if answers:
        for a in answers:
            print(f'  Answer: {a.short_answer[:50]}...')
            print(f'  By: {a.lawyer_title}')
    else:
        print('  No answers yet')
PYTHON_EOF

    # Clean up
    rm -f /tmp/qa_data.json
    docker exec ${CONTAINER_NAME} rm -f /app/qa_data.json

    # Restart the container to ensure all changes are reflected
    echo 'Restarting container to refresh the site...'
    docker restart ${CONTAINER_NAME}
    sleep 10
"

echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

echo ""
echo "✅ Questions and Answers migration completed!"
echo ""
echo "Your recent questions and their lawyer answers have been migrated to the server."
echo "Each question now has its corresponding detailed answer from a lawyer."
echo ""
echo "Check them at https://dadpars.ir"
