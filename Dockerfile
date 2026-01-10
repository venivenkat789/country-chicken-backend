# ================================
# Stage 1: Build the application
# ================================
FROM maven:3.9.9-eclipse-temurin-11 AS build

WORKDIR /app

# Copy pom.xml and download dependencies (cache friendly)
COPY pom.xml ./
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
ARG APP_VERSION=1.0.0
RUN mvn clean package -DskipTests

# ================================
# Stage 2: Runtime image
# ================================
FROM eclipse-temurin:11-jre-jammy

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r spring && useradd -r -g spring spring

# Set working directory
WORKDIR /app

# Copy JAR from build stage (dynamic version)
ARG APP_VERSION=1.0.0
COPY --from=build /app/target/country-chicken-backend-${APP_VERSION}.jar app.jar

# Create logs directory and set permissions
RUN mkdir -p /app/logs && chown -R spring:spring /app

# Switch to non-root user
USER spring:spring

# Expose application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# JVM options
ENV JAVA_OPTS="-Xms256m -Xmx512m \
-XX:+UseG1GC \
-XX:+HeapDumpOnOutOfMemoryError \
-XX:HeapDumpPath=/app/logs"

# Run application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
