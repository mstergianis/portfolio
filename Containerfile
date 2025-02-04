FROM ghcr.io/hugomods/hugo:base AS builder

WORKDIR /app
COPY . /app
RUN hugo build --minify

FROM docker.io/library/nginx:alpine AS runner

COPY --from=builder /app/public /usr/share/nginx/html
