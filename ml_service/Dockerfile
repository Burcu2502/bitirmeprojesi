# Base image
FROM python:3.9-slim

# Çalışma dizinini ayarla
WORKDIR /app

# Sistem bağımlılıklarını kur
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Python bağımlılıklarını kopyala ve kur
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama kodlarını kopyala
COPY . .

# Python modül yolunu ayarla
ENV PYTHONPATH=/app

# Port'u expose et
EXPOSE 5000

# Uygulamayı çalıştır
CMD ["python", "app.py"] 