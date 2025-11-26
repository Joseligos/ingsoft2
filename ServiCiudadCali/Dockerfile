# Usar una imagen oficial de Maven para compilar
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Usar una imagen ligera de Java para ejecutar
FROM eclipse-temurin:21-jre

# Argumentos para metadata
ARG VERSION=unknown
ARG BUILD_DATE
ARG VCS_REF

# Labels de metadata
LABEL com.serviciudadcali.version="${VERSION}" \
      com.serviciudadcali.build-date="${BUILD_DATE}" \
      com.serviciudadcali.vcs-ref="${VCS_REF}" \
      org.opencontainers.image.title="ServiCiudadCali" \
      org.opencontainers.image.description="Sistema de consulta de deudas consolidadas" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}"

WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

# Variable de entorno con la versión
ENV VERSION=${VERSION}

#Con este comando indicamos el puerto que usará la aplicación
EXPOSE 8080

# Comando para ejecutar la aplicación
ENTRYPOINT ["java", "-jar", "app.jar"]