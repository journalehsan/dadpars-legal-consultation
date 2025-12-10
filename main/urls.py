from django.urls import path

from . import views

app_name = "main"

urlpatterns = [
    path("", views.home, name="home"),
    path(
        "test-consultation-types/",
        views.TestConsultationTypesView.as_view(),
        name="test_consultation_types",
    ),
    # path("test-data/", views.TestDataView.as_view(), name="test_data"),
    path(
        "consultation-request/",
        views.ConsultationRequestView.as_view(),
        name="consultation_request",
    ),
    path(
        "consultation-list/",
        views.ConsultationRequestListView.as_view(),
        name="consultation_list",
    ),
    path(
        "question/<int:pk>/",
        views.QuestionDetailView.as_view(),
        name="question_detail",
    ),
    # New consultation pages
    path(
        "24-hours-legal-consultation/",
        views.TwentyFourHoursConsultationView.as_view(),
        name="24_hours_consultation",
    ),
    path(
        "phone-legal-consultation/",
        views.PhoneConsultationView.as_view(),
        name="phone_consultation",
    ),
    path(
        "in-person-legal-consultation/",
        views.InPersonConsultationView.as_view(),
        name="in_person_consultation",
    ),
    path(
        "quick-legal-advice/",
        views.QuickLegalAdviceView.as_view(),
        name="quick_legal_advice",
    ),
]
