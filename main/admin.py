from django.contrib import admin
from .models import FAQ, ConsultationRequest, ConsultationResponse, SiteContent, Service


@admin.register(FAQ)
class FAQAdmin(admin.ModelAdmin):
    list_display = ["question_short", "order", "is_active", "created_at"]
    list_filter = ["is_active", "created_at"]
    search_fields = ["question", "answer"]
    list_editable = ["order", "is_active"]
    ordering = ["order", "created_at"]

    def question_short(self, obj):
        return obj.question[:50] + "..." if len(obj.question) > 50 else obj.question

    question_short.short_description = "سوال"


@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ["title", "icon", "order", "is_active", "created_at"]
    list_filter = ["is_active", "created_at"]
    search_fields = ["title", "description"]
    list_editable = ["order", "is_active"]
    ordering = ["order", "created_at"]


@admin.register(SiteContent)
class SiteContentAdmin(admin.ModelAdmin):
    list_display = ["content_type", "is_active", "updated_at"]
    list_filter = ["content_type", "is_active", "updated_at"]
    search_fields = ["content"]
    list_editable = ["is_active"]
    ordering = ["content_type"]


@admin.register(ConsultationRequest)
class ConsultationRequestAdmin(admin.ModelAdmin):
    list_display = [
        "name",
        "phone",
        "consultation_type",
        "subject_short",
        "status",
        "created_at",
    ]
    list_filter = ["consultation_type", "status", "created_at", "preferred_date"]
    search_fields = ["name", "phone", "subject", "description"]
    list_editable = ["status"]
    ordering = ["-created_at"]
    readonly_fields = ["created_at", "updated_at"]

    fieldsets = (
        ("اطلاعات شخصی", {"fields": ("name", "phone", "email")}),
        ("جزئیات مشاوره", {"fields": ("consultation_type", "subject", "description")}),
        ("زمان پیشنهادی", {"fields": ("preferred_date", "preferred_time")}),
        ("وضعیت", {"fields": ("status",)}),
        ("تاریخ‌ها", {"fields": ("created_at", "updated_at"), "classes": ("collapse",)}),
    )

    def subject_short(self, obj):
        return obj.subject[:30] + "..." if len(obj.subject) > 30 else obj.subject

    subject_short.short_description = "موضوع"


@admin.register(ConsultationResponse)
class ConsultationResponseAdmin(admin.ModelAdmin):
    list_display = ["consultation_request", "responder", "response_date", "is_final"]
    list_filter = ["is_final", "response_date"]
    search_fields = [
        "consultation_request__name",
        "consultation_request__subject",
        "response_text",
    ]
    list_editable = ["is_final"]
    ordering = ["-response_date"]
    readonly_fields = ["response_date"]

    fieldsets = (
        (
            "اطلاعات پاسخ",
            {
                "fields": (
                    "consultation_request",
                    "responder",
                    "response_text",
                    "is_final",
                )
            },
        ),
        ("تاریخ", {"fields": ("response_date",), "classes": ("collapse",)}),
    )
