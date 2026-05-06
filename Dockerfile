# ── Etapa 1: dependencias ─────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# Instalar dependencias de compilación (necesarias para algunos paquetes)
RUN apt-get update && apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./

# Instalar en directorio local para copiar luego
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Etapa 2: imagen final ──────────────────────────────────────
FROM python:3.11-slim

WORKDIR /app

# Crear usuario no-root
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Copiar paquetes instalados
COPY --from=builder /install /usr/local

# Copiar código fuente y plantillas
COPY app.py ./
COPY templates/ ./templates/
# Si tienes archivos estáticos descomenta la línea siguiente:
# COPY static/ ./static/

RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 5000

ENV PORT=5000 \
    DEBUG=False \
    BACKEND_URL=http://backend:3000

# Health check
HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/')" || exit 1

CMD ["python", "app.py"]