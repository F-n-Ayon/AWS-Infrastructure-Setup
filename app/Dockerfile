FROM python:3.10-alpine

WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .
COPY templates/ templates/

# Expose port
EXPOSE 5000

# Health check for ALB - using curl
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Start Flask application
CMD ["python", "app.py"]