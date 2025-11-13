# --- Stage 1: Builder ---
# Use a stable, slim Python base. Pin version for reproducibility.
FROM python:3.12.3-slim-bookworm AS builder

# Create an isolated virtual environment in /opt/venv
WORKDIR /opt/venv
RUN python -m venv . \
 && apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && rm -rf /var/lib/apt/lists/*

# Make sure all pip/python calls use the venv
ENV PATH="/opt/venv/bin:${PATH}"

# Install dependencies (only rebuild this layer when requirements change)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt


# --- Stage 2: Runtime ---
FROM python:3.12.3-slim-bookworm

# Work inside /app
WORKDIR /app

# We are doing this layer first because dependencies first, app later 
# /opt/venv rarely changes and We will likely be updating /app often
# By the Layer caching principle, If any file that 
# was copied before a layer changes,
# every layer after it is invalidated. -

COPY --from=builder /opt/venv /opt/venv

# Copy application source code
# Expect your code under ./app on the host
COPY . ./app

# Create a non-root user with fixed UID/GID and no login shell
# -r  : system account
# -g  : group ID
# -u  : user ID
# -s  : shell (here set to nologin so user can't log in interactively)
RUN groupadd -r -g 1001 appgroup \
 && useradd -r -u 1001 -g appgroup appuser \
 && chown -R appuser:appgroup /app /opt/venv

# Drop privileges to the app user
USER appuser

# Ensure venv Python is used at runtime
ENV PATH="/opt/venv/bin:${PATH}"

# Forces python to flush out logs immediately -no buffer
ENV PYTHONUNBUFFERED=1 

# Health check using Python stdlib (no curl/wget needed)
# Calls GET /healthz on localhost:8000 and exits 0 if status == 200
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["python", "-c", "import http.client, sys; \
conn = http.client.HTTPConnection('localhost', 8000); \
conn.request('GET', '/healthz'); \
resp = conn.getresponse(); \
sys.exit(0 if resp.status == 200 else 1)"]

# FastAPI/ASGI-style app entrypoint: app/main.py defines `app = FastAPI(...)`
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
