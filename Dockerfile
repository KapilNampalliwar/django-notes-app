FROM python:3.9

# Set working directory
WORKDIR /app/backend

# Install system dependencies
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y gcc default-libmysqlclient-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/backend/
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install mysqlclient

# Copy project files
COPY . /app/backend

# Expose port for web service
EXPOSE 8000

# Start Django server by default
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
