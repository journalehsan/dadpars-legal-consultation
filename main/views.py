from django.contrib import messages
from django.contrib.auth.mixins import LoginRequiredMixin
from django.db.models import Q, Count
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


class SearchQuestionsView(View):
    """Search questions in database"""

    def get(self, request):
        query = request.GET.get("q", "").strip()

        if not query:
            return JsonResponse({"questions": []})

        # Search in questions and descriptions
        questions = (
            RecentQuestion.objects.filter(
                Q(question__icontains=query) | Q(description__icontains=query)
            )
            .filter(is_active=True)
            .order_by("-created_at")[:10]
        )

        results = []
        for question in questions:
            results.append(
                {
                    "id": question.id,
                    "question": question.question,
                    "description": question.description[:100] + "..."
                    if question.description and len(question.description) > 100
                    else question.description,
                    "category": question.get_category_display()
                    if hasattr(question, "get_category_display")
                    else "",
                    "url": question.get_absolute_url(),
                    "created_at": question.created_at.strftime("%Y/%m/%d"),
                }
            )

        return JsonResponse({"questions": results})


class QuestionsListView(ListView):
    """List all questions with filtering and sorting"""

    model = RecentQuestion
    template_name = "main/questions_list.html"
    context_object_name = "questions"
    paginate_by = 12

    def get_queryset(self):
        queryset = RecentQuestion.objects.filter(is_active=True)

        # Category filtering
        category = self.request.GET.get("category")
        if category and category != "all":
            queryset = queryset.filter(category=category)

        # Sorting
        sort_by = self.request.GET.get("sort", "newest")
        if sort_by == "newest":
            queryset = queryset.order_by("-created_at")
        elif sort_by == "oldest":
            queryset = queryset.order_by("created_at")
        elif sort_by == "answered":
            queryset = queryset.filter(is_answered=True).order_by("-created_at")
        elif sort_by == "unanswered":
            queryset = queryset.filter(is_answered=False).order_by("-created_at")

        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)

        # Add category choices for filter
        context["category_choices"] = RecentQuestion.CATEGORY_CHOICES
        context["current_category"] = self.request.GET.get("category", "all")
        context["current_sort"] = self.request.GET.get("sort", "newest")

        # Add statistics
        context["total_questions"] = RecentQuestion.objects.filter(
            is_active=True
        ).count()
        context["answered_questions"] = RecentQuestion.objects.filter(
            is_active=True, is_answered=True
        ).count()
        context["unanswered_questions"] = RecentQuestion.objects.filter(
            is_active=True, is_answered=False
        ).count()

        # Get answers count for each question
        question_ids = [q.id for q in context["questions"]]
        answers_count = (
            LawyerAnswer.objects.filter(question_id__in=question_ids, is_active=True)
            .values("question_id")
            .annotate(count=Count("id"))
        )

        answers_dict = {item["question_id"]: item["count"] for item in answers_count}

        for question in context["questions"]:
            question.answers_count = answers_dict.get(question.id, 0)

        return context
