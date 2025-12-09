from django.contrib.auth.models import User
from django.core.management.base import BaseCommand
from django.utils import timezone

from main.models import FAQ, ConsultationType, LawyerAnswer, RecentQuestion, Service


class Command(BaseCommand):
    help = "Create sample data for consultation types, questions and answers"

    def handle(self, *args, **options):
        # Create consultation types
        phone_consultation, created = ConsultationType.objects.get_or_create(
            type_key="phone",
            defaults={
                "title": "مشاوره حقوقی تلفنی",
                "description": "مشاوره حقوقی تلفنی یک گزینه سریع و راحت برای دریافت راهنمایی‌های حقوقی است. وکلای حرفه‌ای می‌توانند از طریق تلفن در کوتاه‌ترین زمان ممکن به سوالات شما پاسخ دهند.",
                "icon": "fas fa-phone-alt",
                "features": "پاسخگویی سریع و فوری\nمناسب برای شهرهای دورافتاده\nصرفه‌جویی در زمان و هزینه",
                "button_text": "تماس فوری",
                "button_url": "tel:09129413828",
                "button_color": "blue",
                "order": 1,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created phone consultation type"))
        else:
            self.stdout.write(
                self.style.WARNING("Phone consultation type already exists")
            )

        online_consultation, created = ConsultationType.objects.get_or_create(
            type_key="online",
            defaults={
                "title": "مشاوره حقوقی آنلاین",
                "description": "مشاوره حقوقی آنلاین از طریق ویدئو کنفرانس، این امکان را می‌دهد که بدون نیاز به مراجعه حضوری، با وکلای متخصص مشورت کنید.",
                "icon": "fas fa-video",
                "features": "مشاوره تصویری با وکیل\nعدم نیاز به مراجعه حضوری\nامکان اشتراک‌گذاری اسناد",
                "button_text": "مشاوره آنلاین",
                "button_url": "#",
                "button_color": "primary",
                "order": 2,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created online consultation type"))
        else:
            self.stdout.write(
                self.style.WARNING("Online consultation type already exists")
            )

        in_person_consultation, created = ConsultationType.objects.get_or_create(
            type_key="in_person",
            defaults={
                "title": "مشاوره حقوقی حضوری",
                "description": "مشاوره حقوقی حضوری بهترین گزینه برای مسائل حقوقی پیچیده و حساس است که نیاز به بررسی مدارک و مستندات بیشتری دارد.",
                "icon": "fas fa-user-tie",
                "features": "بررسی دقیق مدارک و مستندات\nمناسب برای مسائل پیچیده حقوقی\nاعتمادسازی بیشتر با وکیل",
                "button_text": "رزرو وقت حضوری",
                "button_url": "#",
                "button_color": "accent",
                "order": 3,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created in-person consultation type"))
        else:
            self.stdout.write(
                self.style.WARNING("In-person consultation type already exists")
            )

        retired_judge_consultation, created = ConsultationType.objects.get_or_create(
            type_key="retired_judge",
            defaults={
                "title": "مشاوره با قاضی بازنشسته",
                "description": "برای اولین بار در ایران، امکان مشاوره حقوقی با قضات بازنشسته دادگستری را فراهم کرده‌ایم. از تجربه عمیق قضایی و بینش منحصر به فرد قضات بهره‌مند شوید.",
                "icon": "fas fa-gavel",
                "features": "تحلیل پرونده از نگاه قاضی\nپیش‌بینی روند دادرسی\nمشاوره محرمانه\nتضمین امنیت اطلاعات",
                "button_text": "تماس با قاضی",
                "button_url": "#",
                "button_color": "yellow",
                "order": 4,
            },
        )
        if created:
            self.stdout.write(
                self.style.SUCCESS("Created retired judge consultation type")
            )
        else:
            self.stdout.write(
                self.style.WARNING("Retired judge consultation type already exists")
            )

        # Create recent questions
        question1, created = RecentQuestion.objects.get_or_create(
            question="آیا می‌توان از کارفرما به دلیل عدم پرداخت حقوق شکایت کرد؟",
            defaults={
                "description": "حقوقم چند ماه است پرداخت نشده و قصد دارم شکایت کنم. آیا امکان‌پذیر است؟",
                "category": "labor",
                "questioner_name": "کاربر مهمان",
                "is_answered": True,
                "order": 1,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created question 1"))
        else:
            self.stdout.write(self.style.WARNING("Question 1 already exists"))

        question2, created = RecentQuestion.objects.get_or_create(
            question="مراحل طلاق در ایران چیست؟",
            defaults={
                "description": "برای درخواست طلاق، چه مراحلی باید طی شود؟",
                "category": "family",
                "questioner_name": "کاربر مهمان",
                "is_answered": True,
                "order": 2,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created question 2"))
        else:
            self.stdout.write(self.style.WARNING("Question 2 already exists"))

        question3, created = RecentQuestion.objects.get_or_create(
            question="آیا می‌توان قرارداد اجاره یک sidedه را یکطرفه فسخ کرد؟",
            defaults={
                "description": "قرارداد اجاره املاک من سه ماه دیگر تمام می‌شود، اما می‌خواهم زودتر آن را فسخ کنم. آیا امکان‌پذیر است؟",
                "category": "real_estate",
                "questioner_name": "کاربر مهمان",
                "is_answered": True,
                "order": 3,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created question 3"))
        else:
            self.stdout.write(self.style.WARNING("Question 3 already exists"))

        # Get or create a lawyer user
        lawyer_user, created = User.objects.get_or_create(
            username="lawyer1",
            defaults={
                "first_name": "رضا",
                "last_name": "احمدی",
                "email": "lawyer@example.com",
                "is_staff": True,
            },
        )
        if created:
            lawyer_user.set_password("password123")
            lawyer_user.save()
            self.stdout.write(self.style.SUCCESS("Created lawyer user"))
        else:
            self.stdout.write(self.style.WARNING("Lawyer user already exists"))

        # Create lawyer answers
        answer1, created = LawyerAnswer.objects.get_or_create(
            question=question1,
            defaults={
                "lawyer": lawyer_user,
                "answer": "بله، شما می‌توانید از طریق اداره کار و رفاه اجتماعی اقدام به شکایت کنید. طبق قانون کار، کارفرما موظف است حقوق کارگران را در زمان مقرر پرداخت کند. در صورت عدم پرداخت، کارگر می‌تواند به اداره کار مراجعه و شکایت خود را ثبت کند. برای این کار، ابتدا باید یک درخواست کتبی به کارفرما ارائه دهید و در صورت عدم پاسخ، به اداره کار مراجعه کنید. مدارک لازم شامل قرارداد کار، فیش‌های حقوقی و هرگونه مدرک دال بر کارکرد شما می‌باشد.",
                "short_answer": "بله، شما می‌توانید از طریق اداره کار و رفاه اجتماعی اقدام به شکایت کنید.",
                "lawyer_title": "وکیل پایه یک دادگستری",
                "icon": "fas fa-gavel",
                "order": 1,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created answer 1"))
        else:
            self.stdout.write(self.style.WARNING("Answer 1 already exists"))

        answer2, created = LawyerAnswer.objects.get_or_create(
            question=question2,
            defaults={
                "lawyer": lawyer_user,
                "answer": "مراحل طلاق در ایران به دو نوع تقسیم می‌شود: طلاق توافقی و طلاق از طرف丈夫. در طلاق توافقی، زوجین باید در مورد تمام مسائل از جمله مهریه، حضانت فرزندان و نحوه تقسیم اموال به توافق برسند. سپس با همراهی دو نفر مرد عادل به دفترخانه مراجعه کرده و درخواست خود را ثبت می‌کنند. در طلاق از طرف丈夫، ابتدا باید زوجه در دادگاه خانواده شکایت تنظیم کند. سپس جلسات داوری و مشاوره برگزار می‌شود. اگر راه حلی پیدا نشود، دادگاه رأی به طلاق می‌دهد. در هر دو حالت، پس از صدور گواهی عدم امکان سازش، زوجین به دفترخانه مراجعه کرده و طلاق را ثبت می‌کنند.",
                "short_answer": "ابتدا درخواست طلاق به دادگاه ارائه می‌شود و پس از تأیید دادگاه، مراحل ادامه می‌یابد.",
                "lawyer_title": "وکیل متخصص امور خانواده",
                "icon": "fas fa-balance-scale",
                "order": 2,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created answer 2"))
        else:
            self.stdout.write(self.style.WARNING("Answer 2 already exists"))

        answer3, created = LawyerAnswer.objects.get_or_create(
            question=question3,
            defaults={
                "lawyer": lawyer_user,
                "answer": "فسخ یکطرفه قرارداد اجاره شرایط مشخصی دارد. طبق قانون مدنی، مستأجر می‌تواند قبل از انقضای مدت اجاره، قرارداد را فسخ کند فقط در صورتی که در خود قرارداد این شرط ذکر شده باشد (شرط فسخ یکطرفه به نفع مستأجر) یا با رضایت موجر. همچنین شرایطی مانند وصف عدول از معامله یا عدم امکان انتفاع از ملک نیز می‌تواند دلیل فسخ قرارداد باشد. اگر هیچ‌یک از این شرایط وجود نداشته باشد، مستأجر متعهد به پرداخت اجاره‌بها تا پایان مدت قرارداد است. بهتر است ابتدا با موجر مذاکره کنید و در صورت عدم توافق، از مشاوره حقوقی استفاده کنید.",
                "short_answer": "فسخ یکطرفه قرارداد اجاره تنها در صورت وجود شرط فسخ در قرارداد یا رضایت موجر امکان‌پذیر است.",
                "lawyer_title": "وکیل متخصص امور املاک",
                "icon": "fas fa-home",
                "order": 3,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created answer 3"))
        else:
            self.stdout.write(self.style.WARNING("Answer 3 already exists"))

        # Create sample services
        service1, created = Service.objects.get_or_create(
            title="مشاوره حقوقی خانواده",
            defaults={
                "description": "مشاوره تخصصی در امور خانواده شامل طلاق، مهریه، حضانت فرزندان و امور نکاح.",
                "icon": "fas fa-home",
                "order": 1,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created service 1"))
        else:
            self.stdout.write(self.style.WARNING("Service 1 already exists"))

        service2, created = Service.objects.get_or_create(
            title="مشاوره حقوقی کیفری",
            defaults={
                "description": "مشاوره در امور کیفری از جمله جرائم علیه اموال، اشخاص و وجوه و همچنین دفاع از متهمین.",
                "icon": "fas fa-shield-alt",
                "order": 2,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created service 2"))
        else:
            self.stdout.write(self.style.WARNING("Service 2 already exists"))

        service3, created = Service.objects.get_or_create(
            title="مشاوره حقوقی کار و کارگر",
            defaults={
                "description": "مشاوره در حوزه روابط کارگر و کارفرما، بیمه بیکاری، حقوق و مزایا و شکایات کارگری.",
                "icon": "fas fa-briefcase",
                "order": 3,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created service 3"))
        else:
            self.stdout.write(self.style.WARNING("Service 3 already exists"))

        service4, created = Service.objects.get_or_create(
            title="مشاوره امور ملکی",
            defaults={
                "description": "مشاوره در زمینه خرید و فروش، اجاره و انتقال املاک و همچنین دعاوی مربوط به املاک.",
                "icon": "fas fa-building",
                "order": 4,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created service 4"))
        else:
            self.stdout.write(self.style.WARNING("Service 4 already exists"))

        service5, created = Service.objects.get_or_create(
            title="مشاوره حقوقی تجاری",
            defaults={
                "description": "مشاوره در امور شرکت‌ها، قراردادهای تجاری، مالکیت فکری و مسائل مرتبط با کسب و کار.",
                "icon": "fas fa-handshake",
                "order": 5,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created service 5"))
        else:
            self.stdout.write(self.style.WARNING("Service 5 already exists"))

        # Create sample FAQs
        faq1, created = FAQ.objects.get_or_create(
            question="چه کسانی می‌توانند از مشاوره با قاضی بازنشسته استفاده کنند؟",
            defaults={
                "answer": "همه افرادی که با مسائل حقوقی پیچیده روبرو هستند و نیاز به تحلیل تخصصی از نگاه قضایی دارند، می‌توانند از این خدمات استفاده کنند. این نوع مشاوره به ویژه برای پرونده‌هایی که در مراحل دادرسی قرار دارند یا نیاز به نگاهی فراتر از وکالت معمولی دارند، بسیار مفید است.",
                "order": 1,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created FAQ 1"))
        else:
            self.stdout.write(self.style.WARNING("FAQ 1 already exists"))

        faq2, created = FAQ.objects.get_or_create(
            question="تفاوت مشاوره با قاضی بازنشسته و مشاوره با وکیل چیست؟",
            defaults={
                "answer": "قاضی بازنشسته با نگاهی قضایی به پرونده شما می‌پردازد و روند دادرسی را پیش‌بینی می‌کند، در حالی که وکیل بیشتر بر روی راهکارهای قانونی و دفاع از حقوق شما تمرکز دارد. مشاوره با قاضی بازنشسته به شما کمک می‌کند تا از زاویه‌ای دیگر به پرونده خود نگاه کنید و استراتژی بهتری برای دادرسی داشته باشید.",
                "order": 2,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created FAQ 2"))
        else:
            self.stdout.write(self.style.WARNING("FAQ 2 already exists"))

        faq3, created = FAQ.objects.get_or_create(
            question="آیا مشاوره با قاضی بازنشسته محرمانه است؟",
            defaults={
                "answer": "بله، تمام مشاوره‌ها کاملاً محرمانه است و طبق قوانین حقوقی، حریم خصوصی مشتریان حفظ می‌شود. قضات بازنشسته نیز به اصول اخلاقی قضایی پایبند هستند و هیچ‌گونه اطلاعاتی از پرونده شما را فاش نخواهند کرد. شما می‌توانید با اطمینان کامل از این خدمات استفاده کنید.",
                "order": 3,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created FAQ 3"))
        else:
            self.stdout.write(self.style.WARNING("FAQ 3 already exists"))

        faq4, created = FAQ.objects.get_or_create(
            question="هزینه مشاوره با قاضی بازنشسته چقدر است؟",
            defaults={
                "answer": "هزینه مشاوره با قاضی بازنشسته بسته به نوع مسئله حقوقی و زمان مورد نیاز، متفاوت است. برای اطلاع از دقیق‌ترین هزینه‌ها، می‌توانید با شماره‌های مرکز تماس گرفته و بعد از توضیح مختصر مسئله، از هزینه مشاوره مطلع شوید. این هزینه در مقایسه با منافع احتمالی آن، بسیار معقول است.",
                "order": 4,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created FAQ 4"))
        else:
            self.stdout.write(self.style.WARNING("FAQ 4 already exists"))

        faq5, created = FAQ.objects.get_or_create(
            question="آیا امکان مشاوره آنلاین با قاضی بازنشسته وجود دارد؟",
            defaults={
                "answer": "بله، شما می‌توانید به صورت آنلاین و از طریق ویدئو کنفرانس با قاضی بازنشسته مشاوره داشته باشید. این گزینه برای افرادی که امکان مراجعه حضوری ندارند یا در شهرهای دیگر ساکن هستند، بسیار مناسب است. کیفیت مشاوره آنلاین با حضوری تفاوتی ندارد و تمام جزئیات به دقت بررسی می‌شوند.",
                "order": 5,
            },
        )
        if created:
            self.stdout.write(self.style.SUCCESS("Created FAQ 5"))
        else:
            self.stdout.write(self.style.WARNING("FAQ 5 already exists"))

        self.stdout.write(self.style.SUCCESS("Sample data created successfully!"))
