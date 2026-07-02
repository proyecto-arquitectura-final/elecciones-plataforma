# Cambios mínimos en el front Angular

Crear `src/app/services/api.service.ts`:

```ts
import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private base = 'http://localhost:8080/api/v1';
  constructor(private http: HttpClient) {}
  private headers() { return { headers: new HttpHeaders({ Authorization: `Bearer ${localStorage.getItem('token') || ''}` }) }; }
  login(email: string, password: string) { return this.http.post<any>(`${this.base}/auth/login`, { email, password }); }
  partidos() { return this.http.get<any>(`${this.base}/partidos`, this.headers()); }
  candidatos() { return this.http.get<any>(`${this.base}/candidatos`, this.headers()); }
  elecciones() { return this.http.get<any>(`${this.base}/elecciones`, this.headers()); }
  encuestas() { return this.http.get<any>(`${this.base}/encuestas`, this.headers()); }
  resultadosLive() { return this.http.get<any>(`${this.base}/resultados/live`); }
  predicciones() { return this.http.get<any>(`${this.base}/predicciones/resultados-parciales`); }
  chat(question: string) { return this.http.post<any>(`${this.base}/chat/ask`, { question }); }
}
```

En `app.config.ts`, agregar `provideHttpClient()`.
