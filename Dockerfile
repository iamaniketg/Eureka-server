# Step 1: Build
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
#COPY . .
COPY pom.xml .
COPY pom.xml .
RUN mvn -q -DskipTests clean package

# Step 2: Run
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
ENV JAVA_OPTS=""
ENV EUREKA_INSTANCE_HOSTNAME=localhost
EXPOSE 8761
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

