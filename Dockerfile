# Multi-stage Dockerfile for Node.js acquisitions application

# Base image with Node.js
FROM node:24-alpine AS base

# Set working directory
WORKDIR /app

# Copy package files 
COPY package*.json ./

# Install dependencies
# Use npm ci for clean install and remove cache to reduce image size
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Create non-root user for security
# Use a specific UID and GID to avoid conflicts with host system users
RUN addgroup -S -g 1001 appgroup && adduser -S -u 1001 appuser -G appgroup

# Change ownership of the application files to the non-root user
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Expose the application port
EXPOSE 3000

# Health check to ensure the application is running
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1); }).on('error', () => { process.exit(1) });"

# Development stage
FROM base AS development
USER root
RUN npm ci && npm cache clean --force
USER appuser
CMD ["npm", "run", "dev"]

# Production stage
FROM base AS production
CMD ["npm", "start"]