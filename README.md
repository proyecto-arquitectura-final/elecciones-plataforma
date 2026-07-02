# Elecciones Colombia 2026 - Backend

Backend Spring Boot 3 + Java 17 con arquitectura modular:

- `commons`: librería principal con `ApiResponse`, configuración JWT, filtro JWT y beans reutilizables.
- `backend`: API REST para integrar el front Angular del SRS.

## Ejecutar

```bash
mvn clean install
mvn -pl backend spring-boot:run
```

Swagger: `http://localhost:8080/swagger-ui/index.html`

Usuarios semilla:

- admin@elecciones.gov.co / admin1234
- analista@elecciones.gov.co / analista1234

## Endpoints principales

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout`
- `GET|POST|PUT|DELETE /api/v1/usuarios`
- `GET|POST|PUT|DELETE /api/v1/partidos`
- `GET|POST|PUT|DELETE /api/v1/candidatos`
- `GET|POST|PUT|DELETE /api/v1/elecciones`
- `GET|POST|PUT|DELETE /api/v1/encuestas`
- `POST /api/v1/encuestas/import-csv`
- `GET|POST /api/v1/resultados`
- `GET /api/v1/resultados/live`
- `GET /api/v1/predicciones/encuestas`
- `GET /api/v1/predicciones/resultados-parciales`
- `GET /api/v1/reportes/resultados?format=json|csv|pdf`
- `GET /api/v1/auditoria`
- `POST /api/v1/registraduria/sincronizar`
- `GET /api/v1/mcp/tools`
- `POST /api/v1/mcp/invoke`
- `POST /api/v1/chat/ask`

## Login para Angular

```ts
this.http.post<any>('http://localhost:8080/api/v1/auth/login', {
  email: this.correo,
  password: this.contrasena
}).subscribe(res => {
  localStorage.setItem('token', res.data.token);
  const destino = res.data.role === 'ANALISTA' ? '/analista/dashboard' : '/admin/dashboard';
  this.router.navigate([destino]);
});
```

Agregar interceptor con header:

```ts
Authorization: Bearer ${localStorage.getItem('token')}
```

## Notas de cumplimiento SRS

- Contraseñas cifradas con BCrypt.
- JWT stateless.
- RBAC por roles ADMINISTRADOR y ANALISTA.
- Endpoints públicos para resultados/chat y endpoints protegidos para administración.
- Auditoría de acciones administrativas.
- Reportes JSON/CSV/PDF.
- MCP controlado con tools autorizadas, sin SQL libre.
- Mensaje de transparencia: `Predicción ≠ resultado oficial`.
- Timestamp y origen en resultados importados.
