## Step 1: Build
#FROM maven:3.9.6-eclipse-temurin-17 AS build
#WORKDIR /app
#COPY . .
#RUN mvn -q -DskipTests clean package
#
## Step 2: Run
#FROM eclipse-temurin:17-jre-alpine
#WORKDIR /app
#COPY --from=build /app/target/*.jar app.jar
#ENV JAVA_OPTS=""
#ENV EUREKA_INSTANCE_HOSTNAME=localhost
#EXPOSE 8761
#ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]


# Step 1: Build
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
# Copy only pom.xml first for dependency caching
COPY pom.xml .
RUN mvn -q dependency:go-offline
# Now copy source and build
COPY src ./src
RUN mvn -q -DskipTests clean package

# Step 2: Run
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
# Copy specific JAR to avoid wildcard issues
COPY --from=build /app/target/*-SNAPSHOT.jar app.jar  # Adjust if your JAR name is different (e.g., eureka-server-0.0.1-SNAPSHOT.jar)
# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
ENV EUREKA_INSTANCE_HOSTNAME=localhost
EXPOSE 8761
# Add health check for orchestration
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8761/health || exit 1
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]





