from django import forms
from django.utils import timezone
from .models import ConsultationRequest


class ConsultationRequestForm(forms.ModelForm):
    """Form for consultation requests"""

    class Meta:
        model = ConsultationRequest
        fields = [
            "name",
            "phone",
            "email",
            "consultation_type",
            "subject",
            "description",
            "preferred_date",
            "preferred_time",
        ]
        widgets = {
            "name": forms.TextInput(
                attrs={
                    "class": "w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-theme focus:border-transparent transition-all",
                    "placeholder": "نام و نام خانوادگی خود را وارد کنید",
                }
            ),
            "phone": forms.TextInput(
                attrs={
                    "class": "w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-theme focus:border-transparent transition-all",
                    "placeholder": "شماره تماس خود را وارد کنید",
                }
            ),
            "email": forms.EmailInput(
                attrs={
                    "class": "w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-theme focus:border-transparent transition-all",
                    "placeholder": "ایمیل خود را وارد کنید (اختیاری)",
                }
            ),
            "consultation_type": forms.Select(
                attrs={
                    "class": "w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-theme focus:border-transparent transition-all"
                }
            ),
            "subject": forms.TextInput(
                attrs={
                    "class": "w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-theme focus:border-transparent transition-all",
                    "placeholder": "موضوع مشاوره را وارد کنید",
                }
            ),
            "description": forms.Textarea(
                attrs={
                    "class": "w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-theme focus:border-transparent transition-all",
                    "rows": 6,
                    "placeholder": "توضیحات کامل پرونده خود را اینجا بنویسید...",
                }
            ),
            "preferred_date": forms.DateInput(
                attrs={
                    "class": "w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-theme focus:border-transparent transition-all",
                    "type": "date",
                }
            ),
            "preferred_time": forms.TimeInput(
                attrs={
                    "class": "w-full px-4 py-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-theme focus:border-transparent transition-all",
                    "type": "time",
                }
            ),
        }

    def clean_phone(self):
        phone = self.cleaned_data.get("phone")
        # Basic phone validation for Iranian numbers
        if phone and not phone.startswith(("09", "0")):
            raise forms.ValidationError("شماره تماس باید با 09 یا 0 شروع شود.")
        if phone and len(phone) < 10:
            raise forms.ValidationError("شماره تماس نامعتبر است.")
        return phone

    def clean_preferred_date(self):
        date = self.cleaned_data.get("preferred_date")
        if date and date < timezone.now().date():
            raise forms.ValidationError("تاریخ پیشنهادی نمی‌تواند در گذشته باشد.")
        return date
