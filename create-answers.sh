#!/bin/bash

# Script to create admin user and add lawyer answers manually

set -e

# Configuration
SERVER_USER="rocky"
SERVER_IP="37.32.13.22"
SERVER_PASSWORD="Trk@#1403"
CONTAINER_NAME="dadparsir-web"

echo "Creating admin user and adding lawyer answers..."
echo ""

ssh_commands="
    # Create superuser
    echo 'Creating superuser...'
    docker exec ${CONTAINER_NAME} python manage.py shell << 'PYTHON_EOF'
from django.contrib.auth.models import User
from main.models import RecentQuestion, LawyerAnswer

# Create admin user if it doesn't exist
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@dadpars.ir', 'admin123')
    print('Created admin user')

    # Get the admin user
    admin = User.objects.get(username='admin')

    # Get all recent questions
    questions = RecentQuestion.objects.all()

    # Add answers for each question
    answers_data = [
        {
            'question_id': 1,
            'answer': 'بله، شما می‌توانید از طریق اداره کار و رفاه اجتماعی اقدام به شکایت کنید. طبق قانون کار، کارفرما موظف است حقوق کارگران را در زمان مقرر پرداخت کند. در صورت عدم پرداخت، کارگر می‌تواند به اداره کار مراجعه و شکایت خود را ثبت کند. برای این کار، ابتدا باید یک درخواست کتبی به کارفرما ارائه دهید و در صورت عدم پاسخ، به اداره کار مراجعه کنید. مدارک لازم شامل قرارداد کار، فیش‌های حقوقی و هرگونه مدرک دال بر کارکرد شما می‌باشد.',
            'short_answer': 'بله، شما می‌توانید از طریق اداره کار و رفاه اجتماعی اقدام به شکایت کنید.',
            'lawyer_title': 'وکیل پایه یک دادگستری',
            'icon': 'fas fa-gavel'
        },
        {
            'question_id': 2,
            'answer': 'مراحل طلاق در ایران به دو نوع تقسیم می‌شود: طلاق توافقی و طلاق از طرف husband. در طلاق توافقی، زوجین باید در مورد تمام مسائل از جمله مهریه، حضانت فرزندان و نحوه تقسیم اموال به توافق برسند. سپس با همراهی دو نفر مرد عادل به دفترخانه مراجعه کرده و درخواست خود را ثبت می‌کنند. در طلاق از طرف husband، ابتدا باید زوجه در دادگاه خانواده شکایت تنظیم کند. سپس جلسات داوری و مشاوره برگزار می‌شود. اگر راه حلی پیدا نشود، دادگاه رأی به طلاق می‌دهد. در هر دو حالت، پس از صدور گواهی عدم امکان سازش، زوجین به دفترخانه مراجعه کرده و طلاق را ثبت می‌کنند.',
            'short_answer': 'ابتدا درخواست طلاق به دادگاه ارائه می‌شود و پس از تأیید دادگاه، مراحل ادامه می‌یابد.',
            'lawyer_title': 'وکیل متخصص امور خانواده',
            'icon': 'fas fa-balance-scale'
        },
        {
            'question_id': 3,
            'answer': 'فسخ یکطرفه قرارداد اجاره شرایط مشخصی دارد. طبق قانون مدنی، مستأجر می‌تواند قبل از انقضای مدت اجاره، قرارداد را فسخ کند فقط در صورتی که در خود قرارداد این شرط ذکر شده باشد (شرط فسخ یکطرفه به نفع مستأجر) یا با رضایت موجر. همچنین شرایطی مانند وصف عدول از معامله یا عدم امکان انتفاع از ملک نیز می‌تواند دلیل فسخ قرارداد باشد. اگر هیچ‌یک از این شرایط وجود نداشته باشد، مستأجر متعهد به پرداخت اجاره‌بها تا پایان مدت قرارداد است. بهتر است ابتدا با موجر مذاکره کنید و در صورت عدم توافق، از مشاوره حقوقی استفاده کنید.',
            'short_answer': 'فسخ یکطرفه قرارداد اجاره تنها در صورت وجود شرط فسخ در قرارداد یا رضایت موجر امکان‌پذیر است.',
            'lawyer_title': 'وکیل متخصص امور املاک',
            'icon': 'fas fa-home'
        }
    ]

    # Create answers
    for answer_data in answers_data:
        question = RecentQuestion.objects.get(id=answer_data['question_id'])
        LawyerAnswer.objects.update_or_create(
            question=question,
            lawyer=admin,
            defaults={
                'answer': answer_data['answer'],
                'short_answer': answer_data['short_answer'],
                'lawyer_title': answer_data['lawyer_title'],
                'icon': answer_data['icon'],
                'order': answer_data['question_id'],
                'is_active': True
            }
        )
        print(f'Added answer for question: {question.question[:30]}...')

    print('\\nAll answers have been added successfully!')
PYTHON_EOF

    # Verify the data
    echo ''
    echo 'Verifying answers:'
    docker exec ${CONTAINER_NAME} python manage.py shell << 'PYTHON_EOF'
from main.models import RecentQuestion, LawyerAnswer

print(f'Recent Questions: {RecentQuestion.objects.count()}')
print(f'Lawyer Answers: {LawyerAnswer.objects.count()}')
print('')

# Show each question with its answer
for q in RecentQuestion.objects.all():
    print(f'Question {q.id}: {q.question[:50]}...')
    answers = LawyerAnswer.objects.filter(question=q)
    if answers:
        a = answers.first()
        print(f'  ✅ Has answer: {a.short_answer[:50]}...')
    else:
        print('  ❌ No answer')
    print('')
PYTHON_EOF

    # Restart container
    echo 'Restarting container...'
    docker restart ${CONTAINER_NAME}
    sleep 10
"

echo "$ssh_commands" | sshpass -p "$SERVER_PASSWORD" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} /bin/bash

echo ""
echo "✅ Lawyer answers have been successfully added!"
echo ""
echo "Admin user created:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "Each question now has a detailed lawyer answer associated with it."
echo "Check them at https://dadpars.ir"
