from django.db import models
from django.utils import timezone
from django.contrib.auth.models import User


class FAQ(models.Model):
    question = models.TextField(verbose_name="سوال")
    answer = models.TextField(verbose_name="پاسخ")
    order = models.PositiveIntegerField(default=0, verbose_name="ترتیب نمایش")
    is_active = models.BooleanField(default=True, verbose_name="فعال")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="تاریخ ایجاد")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="تاریخ به‌روزرسانی")

    class Meta:
        verbose_name = "سوال متداول"
        verbose_name_plural = "سوالات متداول"
        ordering = ["order", "created_at"]

    def __str__(self):
        question_str = str(self.question)
        return question_str[:50] + "..." if len(question_str) > 50 else question_str


class ConsultationRequest(models.Model):
    CONSULTATION_TYPES = [
        ("phone", "مشاوره تلفنی"),
        ("online", "مشاوره آنلاین"),
        ("retired_judge", "مشاوره با قاضی بازنشسته"),
        ("in_person", "مشاوره حضوری"),
    ]

    STATUS_CHOICES = [
        ("pending", "در انتظار بررسی"),
        ("approved", "تایید شده"),
        ("rejected", "رد شده"),
        ("completed", "انجام شده"),
    ]

    name = models.CharField(max_length=100, verbose_name="نام و نام خانوادگی")
    phone = models.CharField(max_length=20, verbose_name="شماره تماس")
    email = models.EmailField(blank=True, verbose_name="ایمیل")
    consultation_type = models.CharField(
        max_length=20, choices=CONSULTATION_TYPES, verbose_name="نوع مشاوره"
    )
    subject = models.CharField(max_length=200, verbose_name="موضوع مشاوره")
    description = models.TextField(verbose_name="توضیحات")
    preferred_date = models.DateField(verbose_name="تاریخ پیشنهادی")
    preferred_time = models.TimeField(verbose_name="ساعت پیشنهادی")
    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default="pending", verbose_name="وضعیت"
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="تاریخ درخواست")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="تاریخ به‌روزرسانی")

    class Meta:
        verbose_name = "درخواست مشاوره"
        verbose_name_plural = "درخواست‌های مشاوره"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.name} - {self.consultation_type}"


class ConsultationResponse(models.Model):
    consultation_request = models.ForeignKey(
        ConsultationRequest,
        on_delete=models.CASCADE,
        related_name="responses",
        verbose_name="درخواست مشاوره",
    )
    responder = models.ForeignKey(
        User, on_delete=models.CASCADE, verbose_name="پاسخ‌دهنده"
    )
    response_text = models.TextField(verbose_name="متن پاسخ")
    response_date = models.DateTimeField(auto_now_add=True, verbose_name="تاریخ پاسخ")
    is_final = models.BooleanField(default=False, verbose_name="پاسخ نهایی")

    class Meta:
        verbose_name = "پاسخ مشاوره"
        verbose_name_plural = "پاسخ‌های مشاوره"
        ordering = ["response_date"]

    def __str__(self):
        return f"پاسخ به {self.consultation_request.name}"


class SiteContent(models.Model):
    CONTENT_TYPES = [
        ("hero_title", "عنوان اصلی صفحه"),
        ("hero_subtitle", "زیرعنوان اصلی صفحه"),
        ("about_text", "متن درباره ما"),
        ("contact_info", "اطلاعات تماس"),
        ("services", "خدمات"),
        ("testimonials", "نظرات مشتریان"),
    ]

    content_type = models.CharField(
        max_length=50, choices=CONTENT_TYPES, unique=True, verbose_name="نوع محتوا"
    )
    content = models.TextField(verbose_name="محتوا")
    is_active = models.BooleanField(default=True, verbose_name="فعال")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="تاریخ ایجاد")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="تاریخ به‌روزرسانی")

    class Meta:
        verbose_name = "محتوای سایت"
        verbose_name_plural = "محتوای سایت"

    def __str__(self):
        return str(self.content_type)


class Service(models.Model):
    title = models.CharField(max_length=200, verbose_name="عنوان خدمت")
    description = models.TextField(verbose_name="توضیحات")
    icon = models.CharField(max_length=50, verbose_name="آیکون (Font Awesome)")
    order = models.PositiveIntegerField(default=0, verbose_name="ترتیب نمایش")
    is_active = models.BooleanField(default=True, verbose_name="فعال")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="تاریخ ایجاد")

    class Meta:
        verbose_name = "خدمت"
        verbose_name_plural = "خدمات"
        ordering = ["order", "created_at"]

    def __str__(self):
        return str(self.title)
