# Stage 1: Builder
FROM python:3.9-slim as builder
WORKDIR /app
COPY app/ .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Runner
FROM python:3.9-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY app/ .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
