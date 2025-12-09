# Dadpars Legal Site

A Django-based legal consultation website with dynamic content management for questions, answers, and online consultation requests.

## Quick Start

### One-Command Management

Use the management script for easy project control:

```bash
# Initial setup (first time only)
./manage.sh setup

# Start the development server
./manage.sh start

# Stop the server
./manage.sh stop

# Restart the server
./manage.sh restart

# Check server status
./manage.sh status

# Show help
./manage.sh help
```

### Manual Setup (Alternative)

If you prefer manual setup:

```bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install Django python-jalali

# Run migrations
python manage.py makemigrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Start server
python manage.py runserver
```

## Features

### 🏠 **Dynamic Home Page**
- Hero section with animated backgrounds
- Dynamic FAQ section (manageable via admin)
- Services showcase (manageable via admin)
- Responsive design with dark mode support

### 📝 **Online Consultation System**
- Complete consultation request form
- Form validation and error handling
- Admin table for managing requests
- Status tracking (pending, approved, rejected, completed)

### 🛠️ **Admin Panel**
- Full CRUD operations for all content
- FAQ management
- Service management
- Consultation request management
- Site content management

### 🎨 **Design Features**
- Modern Tailwind CSS styling
- RTL (Right-to-Left) support for Persian
- Dark/Light mode toggle
- Responsive mobile design
- Smooth animations and transitions
- SEO optimized with meta tags

## Access Points

- **Website**: http://localhost:8000/
- **Admin Panel**: http://localhost:8000/admin/
- **Consultation Form**: http://localhost:8000/consultation-request/

### Default Admin Credentials
- **Username**: `admin`
- **Password**: `admin123` (when using `./manage.sh setup`)

## Project Structure

```
dadpars_ir_site/
├── manage.sh                 # Management script
├── dadpars_site/            # Django project settings
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── main/                    # Main Django app
│   ├── models.py           # Database models
│   ├── views.py            # View functions
│   ├── forms.py            # Form classes
│   ├── admin.py            # Admin configuration
│   ├── urls.py             # App URLs
│   └── templates/main/     # HTML templates
│       ├── base.html       # Base template
│       ├── home.html       # Home page
│       └── consultation_request.html
├── static/                 # Static files (CSS, JS, images)
├── media/                  # User uploaded files
└── db.sqlite3             # SQLite database
```

## Database Models

### **FAQ**
- Questions and answers for the FAQ section
- Ordering and active status management

### **ConsultationRequest**
- Online consultation requests
- Multiple consultation types (phone, online, retired judge, in-person)
- Status tracking and preferred time management

### **Service**
- Services displayed on the home page
- Icon support and ordering

### **SiteContent**
- Manageable site content sections
- Dynamic content management

## Management Script Commands

| Command | Description |
|---------|-------------|
| `./manage.sh setup` | Initial project setup (creates venv, installs dependencies, runs migrations) |
| `./manage.sh start` | Start the development server in background |
| `./manage.sh stop` | Stop the running server |
| `./manage.sh restart` | Restart the server |
| `./manage.sh status` | Show server status and resource usage |
| `./manage.sh help` | Show available commands |

## Development

### Adding New Content

1. **FAQs**: Go to Admin Panel → FAQs → Add new FAQ
2. **Services**: Go to Admin Panel → Services → Add new service
3. **Site Content**: Go to Admin Panel → Site Contents → Edit content

### Managing Consultations

1. **View Requests**: Admin Panel → Consultation requests
2. **Update Status**: Change request status (pending → approved → completed)
3. **Add Responses**: Add detailed responses to requests

### Customization

- **Templates**: Edit files in `main/templates/main/`
- **Styles**: Modify Tailwind classes in templates
- **Models**: Add new models in `main/models.py`
- **Views**: Add new views in `main/views.py`

## Deployment

For production deployment:

1. Set `DEBUG = False` in `settings.py`
2. Configure `ALLOWED_HOSTS`
3. Set up production database
4. Configure static files serving
5. Set up domain and SSL

## Requirements

- Python 3.8+
- Django 6.0
- jdatetime (for Persian date support)

## Support

For issues or questions:
1. Check the server logs: `tail -f server.log`
2. Verify virtual environment is activated
3. Ensure all dependencies are installed
4. Check database migrations are up to date

---

**Note**: This project is designed for Persian/Farsi language support with RTL layout and proper localization.