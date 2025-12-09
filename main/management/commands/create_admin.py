from django.contrib.auth.models import User
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Create a superuser with username=admin and password=admin123"

    def handle(self, *args, **options):
        if not User.objects.filter(username="admin").exists():
            User.objects.create_superuser("admin", "admin@example.com", "admin123")
            self.stdout.write(
                self.style.SUCCESS(
                    "Successfully created admin user with admin/admin123"
                )
            )
        else:
            self.stdout.write(self.style.WARNING("Admin user already exists"))
