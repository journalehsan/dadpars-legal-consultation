from django.core.management.base import BaseCommand
from django.http import HttpRequest
from django.template.loader import render_to_string

from main.models import FAQ, ConsultationType, LawyerAnswer, RecentQuestion, Service


class Command(BaseCommand):
    help = "Test template rendering with actual data"

    def handle(self, *args, **options):
        # Fetch data like in home view
        faqs = FAQ.objects.filter(is_active=True).order_by("order", "created_at")[:6]
        services = Service.objects.filter(is_active=True).order_by(
            "order", "created_at"
        )
        consultation_types = ConsultationType.objects.filter(is_active=True).order_by(
            "order", "created_at"
        )
        recent_questions = RecentQuestion.objects.filter(is_active=True).order_by(
            "order", "-created_at"
        )[:5]
        lawyer_answers = (
            LawyerAnswer.objects.filter(is_active=True)
            .select_related("question", "lawyer")
            .order_by("order", "-created_at")[:5]
        )

        # Create context
        context = {
            "faqs": faqs,
            "services": services,
            "consultation_types": consultation_types,
            "recent_questions": recent_questions,
            "lawyer_answers": lawyer_answers,
        }

        # Create a simple test template
        template_content = """
        <h1>Template Test Results</h1>

        <h2>Consultation Types ({{ consultation_types|length }} items)</h2>
        <ul>
        {% for consultation in consultation_types %}
        <li>{{ consultation.title }} - {{ consultation.button_color }}</li>
        {% endfor %}
        </ul>

        <h2>Recent Questions ({{ recent_questions|length }} items)</h2>
        <ul>
        {% for question in recent_questions %}
        <li>{{ question.question }}</li>
        {% endfor %}
        </ul>

        <h2>Lawyer Answers ({{ lawyer_answers|length }} items)</h2>
        <ul>
        {% for answer in lawyer_answers %}
        <li>{{ answer.question.question|truncatewords:3 }} - {{ answer.short_answer }}</li>
        {% endfor %}
        </ul>

        <h2>Services ({{ services|length }} items)</h2>
        <ul>
        {% for service in services %}
        <li>{{ service.title }}</li>
        {% endfor %}
        </ul>

        <h2>FAQs ({{ faqs|length }} items)</h2>
        <ul>
        {% for faq in faqs %}
        <li>{{ faq.question }}</li>
        {% endfor %}
        </ul>
        """

        # Render the template
        request = HttpRequest()
        rendered = render_to_string(template_content, context, request)

        # Print results
        print(rendered)

        # Print summary
        self.stdout.write(self.style.SUCCESS("Template rendered successfully!"))
        self.stdout.write(f"Found {consultation_types.count()} consultation types")
        self.stdout.write(f"Found {recent_questions.count()} recent questions")
        self.stdout.write(f"Found {lawyer_answers.count()} lawyer answers")
        self.stdout.write(f"Found {services.count()} services")
        self.stdout.write(f"Found {faqs.count()} FAQs")
