from django.shortcuts import render, redirect
from django.contrib import messages
from django.views.generic import ListView
from django.views.generic.edit import FormView
from django.urls import reverse_lazy
from django.contrib.auth.mixins import LoginRequiredMixin
from .models import FAQ, ConsultationRequest, Service
from .forms import ConsultationRequestForm


def home(request):
    """Home page view with dynamic content"""
    faqs = FAQ.objects.filter(is_active=True).order_by("order", "created_at")[:6]
    services = Service.objects.filter(is_active=True).order_by("order", "created_at")

    context = {
        "faqs": faqs,
        "services": services,
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


class ConsultationRequestListView(LoginRequiredMixin, ListView):
    """List of consultation requests for admin users"""

    model = ConsultationRequest
    template_name = "main/consultation_list.html"
    context_object_name = "requests"
    paginate_by = 20

    def get_queryset(self):
        return ConsultationRequest.objects.select_related().order_by("-created_at")
