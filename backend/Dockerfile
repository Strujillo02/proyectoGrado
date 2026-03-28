FROM eclipse-temurin:17-jdk-alpine

ARG JAR_FILE=target/backend-0.0.1-SNAPSHOT.jar

WORKDIR /app

COPY ${JAR_FILE} proyectoApi.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "proyectoApi.jar"]
