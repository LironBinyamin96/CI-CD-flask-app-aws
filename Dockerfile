FROM python:3.10-slim

WORKDIR /app

# Create flask-app folder and copy code inside
RUN mkdir -p /app/flask-app

COPY backend-py /app/flask-app/backend-py

COPY frontend /app/flask-app/frontend

# Ensure the script is executable
RUN chmod +x /app/flask-app/backend-py/start-server.sh

# Install backend requirements
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r /app/flask-app/backend-py/requirements.txt

# Set the default command to run the script
CMD ["/app/flask-app/backend-py/start-server.sh"]
