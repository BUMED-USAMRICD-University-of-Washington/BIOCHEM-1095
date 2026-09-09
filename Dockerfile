# Use an official, minimal Python runtime base image
FROM python:3.11-slim

# Set system environment adjustments
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Establish the internal working directory
WORKDIR /app

# Install system dependencies needed for compiling standard spatial libraries if necessary
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy python dependencies layout
COPY requirements.txt .

# Install dependencies securely
RUN pip install --no-cache-dir -r requirements.txt

# Copy over the entire application codebase into the active container context
COPY . .

# Expose the default asynchronous server port
EXPOSE 8000

# Execute the web application process using the standardized server layer
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
