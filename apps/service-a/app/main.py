import logging
import uvicorn
import signal
import sys
from fastapi import FastAPI, Request
from pythonjsonlogger import jsonlogger

# Import our settings instance
from .config import settings

# --- 1. Structured Logging Setup ---

# Get the root logger
logger = logging.getLogger()
logger.setLevel(settings.LOG_LEVEL.upper())

# Remove default handlers to avoid duplicate logs
if logger.hasHandlers():
    logger.handlers.clear()

# Create a JSON formatter
formatter = jsonlogger.JsonFormatter(
    '%(asctime)s %(levelname)s %(name)s %(message)s'
)
# Add the formatter to a new stream handler
logHandler = logging.StreamHandler()
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)

# --- 2. Graceful Shutdown Handler ---

# This creates a Uvicorn server instance that we can control
server = None

def setup_graceful_shutdown(app_instance: FastAPI):
    global server
    
    class GracefulShutdownServer(uvicorn.Server):
        def handle_exit(self, sig: int, frame):
            logger.info("Shutdown signal received. Starting graceful shutdown...")
            # This triggers Uvicorn's existing graceful shutdown
            super().handle_exit(sig, frame)

    config = uvicorn.Config(app_instance, host="0.0.0.0", port=8000, log_config=None)
    server = GracefulShutdownServer(config=config)

    # Re-assign signal handlers to Uvicorn's logic
    signal.signal(signal.SIGTERM, server.handle_exit)
    signal.signal(signal.SIGINT, server.handle_exit)

# --- 3. FastAPI Application ---

app = FastAPI(title=settings.APP_NAME)

# This logger will be used for our application-specific logs
app_logger = logging.getLogger(__name__)
app_logger.info(f"Application '{settings.APP_NAME}' starting up...")

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Middleware to log every request in JSON format."""
    app_logger.info(
        f"Request: {request.method} {request.url.path}",
        extra={"method": request.method, "path": request.url.path, "client": request.client.host}
    )
    response = await call_next(request)
    app_logger.info(
        f"Response: {response.status_code}",
        extra={"status_code": response.status_code}
    )
    return response

@app.get("/", tags=["General"])
def read_root():
    """Simple 'Hello World' endpoint."""
    app_logger.debug("Root endpoint was hit")
    return {"message": "Hello from service-a"}

@app.get("/healthz", tags=["Health"])
def health_check():
    """
    Health check endpoint for liveness probes (e.g., Kubernetes).
    Returns a 200 OK if the app is running.
    """
    return {"status": "ok"}

@app.get("/config", tags=["General"])
def show_config():
    """Endpoint to demonstrate configuration loading (for demo purposes)."""
    # WARNING: Never expose secrets like this in a real app
    app_logger.warning("Configuration endpoint was accessed")
    return {
        "app_name": settings.APP_NAME,
        "log_level": settings.LOG_LEVEL,
        "db_host": settings.POSTGRES_HOST,
        "redis_host": settings.REDIS_HOST
    }

# --- 4. Main Entrypoint ---

if __name__ == "__main__":
    # This is the entrypoint for running the app directly
    # e.g., 'python app/main.py'
    
    # We call our setup function to enable graceful shutdown
    setup_graceful_shutdown(app)
    
    # This will block and run the server
    logger.info("Starting server with graceful shutdown enabled...")
    server.run()
