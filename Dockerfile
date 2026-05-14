# ─────────────────────────────────────────────
# Etapa 1: build / instalación de dependencias
# ─────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# Evitar archivos .pyc y buffering en logs
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Instalar dependencias del sistema necesarias para compilar wheels
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./

# Instalar en directorio local para copiarlo limpiamente
RUN pip install --upgrade pip \
    && pip install --prefix=/install -r requirements.txt

# ─────────────────────────────────────────────
# Etapa 2: imagen final
# ─────────────────────────────────────────────
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Usuario sin privilegios
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Copiar librerías instaladas desde el builder
COPY --from=builder /install /usr/local

# Copiar código fuente
COPY app.py ./
COPY requirements.txt ./
COPY templates/ ./templates/

# Establecer propietario
RUN chown -R appuser:appgroup /app
USER appuser

# Puerto que expone Flask
EXPOSE 5000

# Variables de entorno por defecto
ENV FLASK_ENV=production \
    PORT=5000

# Comando de inicio
CMD ["python", "app.py"]