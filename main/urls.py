from django.urls import path
from . import views

app_name = "main"

urlpatterns = [
    path("", views.home, name="home"),
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
]
