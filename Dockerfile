FROM python:3.9-slim

WORKDIR /app

COPY frontend-backend/backend-py/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY frontend-backend/backend-py/ .

EXPOSE 5000

CMD ["python", "server.py"]
