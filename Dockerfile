# Multi-stage build for Country Chicken Backend

# Stage 1: Build the application
FROM maven:3.8.4-openjdk-11-slim AS build
WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the application
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Create the runtime image
FROM openjdk:11-jre-slim

# Add necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN groupadd -r spring && useradd -r -g spring spring
USER spring:spring

# Set working directory
WORKDIR /app

# Copy the JAR file from build stage
COPY --from=build /app/target/country-chicken-backend-1.0.0.jar app.jar

# Create log directory
RUN mkdir -p /app/logs && chown spring:spring /app/logs

# Expose port
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# Set JVM options
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/logs"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]