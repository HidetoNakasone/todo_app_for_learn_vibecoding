FROM node:24-alpine
RUN apk update && \
  apk add --no-cache bash git libc6-compat curl
WORKDIR /app

# Install Bun
RUN npm install -g bun@latest
