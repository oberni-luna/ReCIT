FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /srv
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app app
COPY assets assets

RUN useradd --system --no-create-home preview \
    && mkdir -p /var/cache/exlibris-preview \
    && chown preview /var/cache/exlibris-preview
USER preview

EXPOSE 8620
CMD ["python", "-m", "app.server"]
