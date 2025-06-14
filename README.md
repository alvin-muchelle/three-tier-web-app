## 🛠️ Deployment Architecture (EC2 + Nginx + Gunicorn + Django)

This project is deployed on an Amazon EC2 instance using a **three-tier architecture**:

1. **Web Tier:** Nginx (Reverse Proxy)
2. **Application Tier:** Django (running on Gunicorn)
3. **Data Tier:** PostgreSQL (RDS)

---

### 🔗 Component Overview

| Layer       | Component            | Role                                                          |
| ----------- | -------------------- | ------------------------------------------------------------- |
| Web Tier    | **Nginx**            | Handles HTTP requests, reverse-proxies to the app layer       |
| App Tier    | **Gunicorn**         | WSGI server that runs the Django app                          |
| Logic Layer | **Django**           | Core backend logic, routing, API, templates, and DB access    |
| Data Tier   | **PostgreSQL (RDS)** | Stores app data like mothers, babies, reminders, and schedule |

---

### ⚙️ How It Works

#### 1. **Nginx** (Port `80`)

* Acts as the entry point to the system.
* Forwards HTTP requests to an internal ALB DNS or directly to Gunicorn.
* Configured via `/etc/nginx/conf.d/reverse-proxy.conf`.

```nginx
location / {
    proxy_pass http://${internal_alb_dns};
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

#### 2. **Gunicorn** (Port `8000`)

* Production-grade WSGI server that loads the Django app.
* Managed by `systemd` (`gunicorn.service`), set to auto-start and auto-restart.

```bash
ExecStart=/home/ec2-user/employee_management/venv/bin/gunicorn \
  --bind 0.0.0.0:8000 employee_management.wsgi:application
```

#### 3. **Django**

* Python-based web framework that handles:

  * URL routing
  * Request/response logic
  * Database interaction
  * Admin dashboard
* Loads secrets from AWS Secrets Manager (e.g., DB credentials, Django secret key).
* Renders views like:

  * `/` – homepage
  * `/health/` – health check endpoint
* Writes secrets to a `.env` file which Django reads using `python-dotenv`.

#### 4. **PostgreSQL (RDS)**

* Stores structured data.
* Credentials (host, dbname, user, password) are pulled securely from Secrets Manager.

---

### 🧪 Health Check

* Health check endpoint for load balancer:

  ```
  GET /health/
  ```

  Returns: `200 OK`

---

### 🔐 Security and Secrets

* **Secrets are managed in AWS Secrets Manager**, including:

  * `psql-rds-credentials` (DB login)
  * `django-secret-key` (SECRET\_KEY)

These are fetched and written to `.env`, which is loaded by Django using `load_dotenv`.

---

### 🚀 Deployment Steps Summary

The EC2 `User Data` script:

1. Installs Python, PostgreSQL client, and dependencies.
2. Installs Django + Gunicorn in a Python virtual environment.
3. Fetches secrets and writes a `.env` file.
4. Sets up Django project and migrations.
5. Starts Gunicorn as a systemd service.
6. Installs Nginx and configures it to reverse proxy to Gunicorn.
7. Starts Nginx.

---

### 🗺️ Request Lifecycle

```text
Client Request (HTTP)
        │
        ▼
     [ Nginx ]
        │
        ▼
   [ ALB or localhost ]
        │
        ▼
    [ Gunicorn ]
        │
        ▼
     [ Django ]
        │
        ▼
  [ PostgreSQL (RDS) ]
```

* Nginx receives the request on port `80`.
* It proxies the request to Gunicorn on port `8000`.
* Gunicorn invokes the Django app via WSGI.
* Django processes the request, fetches any data it needs from PostgreSQL.
* Response flows back up the stack to the client.

---
