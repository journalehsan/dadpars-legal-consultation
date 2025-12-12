from django.contrib import messages
from django.contrib.auth.mixins import LoginRequiredMixin
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse_lazy
from django.views.generic import DetailView, ListView, View
from django.views.generic.edit import FormView

from .forms import ConsultationRequestForm
from .models import (
    FAQ,
    ConsultationRequest,
    ConsultationType,
    LawyerAnswer,
    RecentQuestion,
    Service,
)


def home(request):
    """Home page view with dynamic content"""
    faqs = FAQ.objects.filter(is_active=True).order_by("order", "created_at")[:6]
    services = Service.objects.filter(is_active=True).order_by("order", "created_at")

    # Get consultation types
    consultation_types = ConsultationType.objects.filter(is_active=True).order_by(
        "order", "created_at"
    )

    # Get recent questions and answers
    recent_questions = RecentQuestion.objects.filter(is_active=True).order_by(
        "order", "-created_at"
    )[:5]
    lawyer_answers = (
        LawyerAnswer.objects.filter(is_active=True)
        .select_related("question", "lawyer")
        .order_by("order", "-created_at")[:5]
    )

    context = {
        "faqs": faqs,
        "services": services,
        "consultation_types": consultation_types,
        "recent_questions": recent_questions,
        "lawyer_answers": lawyer_answers,
    }
    return render(request, "main/home.html", context)


class ConsultationRequestView(FormView):
    """Consultation request form view"""

    template_name = "main/consultation_request.html"
    form_class = ConsultationRequestForm
    success_url = reverse_lazy("consultation_request")

    def form_valid(self, form):
        form.save()
        messages.success(
            self.request,
            "درخواست مشاوره شما با موفقیت ثبت شد. در اسرع وقت با شما تماس گرفته خواهد شد.",
        )
        return super().form_valid(form)

    def form_invalid(self, form):
        messages.error(
            self.request, "خطا در ثبت درخواست. لطفاً اطلاعات را به درستی وارد کنید."
        )
        return super().form_invalid(form)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        if self.request.user.is_authenticated and self.request.user.is_staff:
            context["consultation_requests"] = (
                ConsultationRequest.objects.select_related().order_by("-created_at")[
                    :10
                ]
            )
        return context


class TestConsultationTypesView(View):
    """Test view to check if consultation types data is being fetched correctly"""

    def get(self, request):
        # Fetch consultation types
        consultation_types = ConsultationType.objects.filter(is_active=True).order_by(
            "order", "created_at"
        )
        context = {
            "consultation_types": consultation_types,
        }

        return render(request, "main/test/consultation_types.html", context)


class ConsultationRequestListView(LoginRequiredMixin, ListView):
    """List of consultation requests for admin users"""

    model = ConsultationRequest
    template_name = "main/consultation_list.html"
    context_object_name = "requests"
    paginate_by = 20

    def get_queryset(self):
        return ConsultationRequest.objects.select_related().order_by("-created_at")


class QuestionDetailView(DetailView):
    """Detail view for a question and its answers"""

    model = RecentQuestion
    template_name = "main/question_detail.html"
    context_object_name = "question"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        # Get the answers for this question
        context["answers"] = (
            LawyerAnswer.objects.filter(question=self.object, is_active=True)
            .select_related("lawyer")
            .order_by("order", "-created_at")
        )
        return context


class TwentyFourHoursConsultationView(View):
    """24-hour legal consultation page view"""

    def get(self, request):
        # Get consultation types for 24-hour service
        consultation_types = ConsultationType.objects.filter(
            is_active=True, type_key__in=["phone", "online"]
        ).order_by("order", "created_at")

        # Get FAQs related to 24-hour consultation
        faqs = FAQ.objects.filter(is_active=True).order_by("order", "created_at")[:8]

        context = {
            "consultation_types": consultation_types,
            "faqs": faqs,
        }
        return render(request, "main/24_hours_legal_consultation.html", context)


class PhoneConsultationView(View):
    """Phone legal consultation page view"""

    def get(self, request):
        # Get consultation types for phone service
        consultation_types = ConsultationType.objects.filter(
            is_active=True, type_key="phone"
        ).order_by("order", "created_at")

        # Get FAQs related to phone consultation
        faqs = FAQ.objects.filter(is_active=True).order_by("order", "created_at")[:8]

        context = {
            "consultation_types": consultation_types,
            "faqs": faqs,
        }
        return render(request, "main/phone_legal_consultation.html", context)


class InPersonConsultationView(View):
    """In-person legal consultation page view"""

    def get(self, request):
        # Get consultation types for in-person service
        consultation_types = ConsultationType.objects.filter(
            is_active=True, type_key="in_person"
        ).order_by("order", "created_at")

        # Get FAQs related to in-person consultation
        faqs = FAQ.objects.filter(is_active=True).order_by("order", "created_at")[:8]

        context = {
            "consultation_types": consultation_types,
            "faqs": faqs,
        }
        return render(request, "main/in_person_legal_consultation.html", context)


class QuickLegalAdviceView(View):
    """Quick legal advice page view"""

    def get(self, request):
        # Get consultation types for quick advice
        consultation_types = ConsultationType.objects.filter(
            is_active=True, type_key__in=["phone", "online"]
        ).order_by("order", "created_at")

        # Get FAQs related to quick advice
        faqs = FAQ.objects.filter(is_active=True).order_by("order", "created_at")[:8]

        context = {
            "consultation_types": consultation_types,
            "faqs": faqs,
        }
        return render(request, "main/quick_legal_advice.html", context)


class ContactView(View):
    """Contact page view"""

    def get(self, request):
        # Get consultation types for the form
        consultation_types = ConsultationType.objects.filter(is_active=True).order_by(
            "order", "created_at"
        )

        # Get FAQs for contact page
        faqs = FAQ.objects.filter(is_active=True).order_by("order", "created_at")[:6]

        context = {
            "consultation_types": consultation_types,
            "faqs": faqs,
        }
        return render(request, "main/contact.html", context)


class RetiredJudgeConsultationView(View):
    """Retired judge consultation page view"""

    def get(self, request):
        # Get consultation types for retired judge service
        consultation_types = ConsultationType.objects.filter(
            is_active=True, type_key__in=["phone", "online", "in_person"]
        ).order_by("order", "created_at")

        # Get FAQs related to retired judge consultation
        faqs = FAQ.objects.filter(is_active=True).order_by("order", "created_at")[:8]

        context = {
            "consultation_types": consultation_types,
            "faqs": faqs,
        }
        return render(request, "main/retired_judge_consultation.html", context)
