# retroai

Plataforma de gestión para complejos deportivos (Pádel/Fútbol 5) con integración de Bot de WhatsApp para rosters y confirmaciones automáticas.

## Estructura del Proyecto

- **/**: Monolito de Ruby on Rails 8 (Panel de Administración, Lógica de Negocio, Reportes).
- **/whatsapp-service**: Servicio de Node.js/TypeScript basado en Baileys que actúa como adaptador para la comunicación con WhatsApp.

## Requisitos

- Ruby 3.4.9
- Node.js 22+
- PostgreSQL

## Desarrollo

1. Iniciar Rails: `bin/dev`
2. Iniciar WhatsApp Service: `cd whatsapp-service && npm run dev`

## Despliegue

Despliegue con [Kamal](https://kamal-deploy.org/) a un único droplet de DigitalOcean, corriendo los servicios `web` (Rails) y `whatsapp` (adaptador Node) más el accesorio `db` (Postgres) — ver `config/deploy.yml`.

1. **Prerrequisitos**:
   - Droplet de DigitalOcean (4GB RAM / 2vCPU, ver `_bmad-output/planning-artifacts/architecture.md`).
   - Clave SSH del droplet cargada en el agente local (`ssh-add`).
   - Docker instalado localmente (Kamal lo usa para ciertas operaciones aunque las imágenes ya las publica CI, ver Story 6.1).
2. **Reemplazar el placeholder de IP**: `config/deploy.yml` usa `203.0.113.10` como placeholder en tres lugares — `servers.web`, `accessories.db.host` y `accessories.whatsapp.host`. Reemplazar los tres por la IP real del droplet (deben coincidir, es un solo servidor).
3. **Generar y exportar secrets** (nunca commitear valores reales — ver `.kamal/secrets`):
   - `RETROAI_DATABASE_PASSWORD`: generar una vez con `openssl rand -hex 32` y guardarlo fuera del repo (gestor de contraseñas o variable de entorno del lugar desde donde se corre `kamal`).
   - `KAMAL_REGISTRY_PASSWORD`: Personal Access Token de GitHub (scope `read:packages`), generado a mano en GitHub → Settings → Developer settings → Personal access tokens. No es el `GITHUB_TOKEN` efímero de Actions.
   - Alternativamente, cargar ambos en un password manager soportado por `kamal secrets fetch` (ver comentarios en `.kamal/secrets`).
4. **Primer despliegue**: `bin/kamal setup` (provisiona Docker y accesorios en el droplet desde cero).
5. **Despliegues siguientes**: `bin/kamal deploy`.
6. **Logs**: `bin/kamal app logs` (alias `bin/kamal logs`), `bin/kamal accessory logs db`, `bin/kamal accessory logs whatsapp`.
