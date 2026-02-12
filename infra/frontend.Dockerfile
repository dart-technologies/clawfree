# Stage 1: Build Flutter Web
FROM debian:bookworm AS build

RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils libglu1-mesa \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Build args — passed from docker-compose
ARG GATEWAY_TOKEN=""
ARG DEMO_MODE="true"

# Copy project files
COPY . .

# Build web — GATEWAY_URL=/api lets the client proxy through Nginx
# DEMO_MODE defaults to true so the QA stack works without a real API key.
# Set DEMO_MODE=false + ANTHROPIC_API_KEY when a live gateway is available.
RUN flutter pub get && \
    flutter build web --release \
      --dart-define=GATEWAY_URL=/api \
      --dart-define=GATEWAY_TOKEN=${GATEWAY_TOKEN} \
      --dart-define=DEMO_MODE=${DEMO_MODE}

# Stage 2: Serve with Nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

# Nginx config: SPA fallback + reverse proxy to OpenClaw gateway
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name _;

    # SPA: serve index.html for all frontend routes
    location / {
        root /usr/share/nginx/html;
        try_files \$uri \$uri/ /index.html;
    }

    # Proxy /api to OpenClaw gateway (SSE + WebSocket friendly)
    location /api/ {
        proxy_pass http://openclaw:18789/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_cache_bypass \$http_upgrade;
        proxy_buffering off;
        proxy_read_timeout 300s;
    }

    # Health check endpoint for container orchestrators
    location /healthz {
        return 200 'ok';
        add_header Content-Type text/plain;
    }
}
EOF

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget -q --spider http://localhost/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
