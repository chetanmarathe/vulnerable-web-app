# Run the application with reduced privileges
FROM node:18-alpine AS build

# Create a non-root user to run the application
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies with exact versions and production only
RUN npm ci --only=production && \
    # Remove npm cache to reduce image size
    npm cache clean --force

# Copy application code
COPY --chown=appuser:appgroup . .

# Use multi-stage build to create a smaller final image
FROM node:18-alpine AS runtime

# Set environment variables
ENV NODE_ENV=production \
    # Disable Node.js process warnings
    NODE_OPTIONS="--no-warnings" \
    # Explicitly set user
    USER=appuser

# Create a non-root user to run the application
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy only necessary files from build stage
COPY --from=build --chown=appuser:appgroup /app/node_modules /app/node_modules
COPY --from=build --chown=appuser:appgroup /app/src /app/src
COPY --from=build --chown=appuser:appgroup /app/package.json /app/

# Create directory for data with proper permissions
RUN mkdir -p /app/data && chown -R appuser:appgroup /app/data

# Apply security hardening
RUN apk add --no-cache dumb-init && \
    # Remove unnecessary tools
    rm -rf /usr/local/lib/node_modules/npm && \
    # Set proper permissions
    chmod -R 755 /app

# Switch to non-root user
USER appuser

# Use dumb-init as entrypoint to handle signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Expose application port
EXPOSE 3000

# Run the application
CMD ["node", "src/app.js"]