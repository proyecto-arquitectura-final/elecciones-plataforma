# Solución error Maven `pom:unknown` / descarga cacheada

Este error no es del código Java: Maven dejó cacheada una descarga fallida en tu repositorio local `.m2`.

## Opción rápida

Desde la raíz del proyecto, ejecuta:

```bash
mvn -U clean install
```

## Si sigue igual en Windows

Cierra IntelliJ y borra solo la carpeta cacheada:

```bat
rmdir /s /q "%USERPROFILE%\.m2epository\org\springframeworkoot\spring-boot-starter-validation"
rmdir /s /q "%USERPROFILE%\.m2epository\org\springframeworkoot\spring-boot-dependencies"
```

Luego:

```bat
mvn -U clean install
```

## En IntelliJ

1. Abre el proyecto desde el `pom.xml` raíz, no desde `backend/pom.xml`.
2. Maven panel → Reload All Maven Projects.
3. Marca Force update snapshots/releases, o usa Reimport con `-U`.
4. Verifica Maven home y JDK 17 en Settings → Build Tools → Maven.

## Nota

Los módulos `commons` y `backend` heredan versiones desde el `pom.xml` padre mediante el BOM de Spring Boot `3.3.5`. Por eso los starters de Spring Boot no llevan versión directa.
