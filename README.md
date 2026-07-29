# Sistema de Evaluación Docente — Despliegue

**Universidad Francisco de Paula Santander (UFPS)**

---

## Descripción

Este repositorio contiene la configuración de Docker Compose para desplegar el **Sistema de Evaluación Docente** en el servidor de la UFPS. El sistema consta de tres servicios:

| Servicio  | Imagen                                       | Descripción                                      |
| --------- | -------------------------------------------- | ------------------------------------------------ |
| `nginx`   | `nginx:alpine`                               | Reverse proxy que expone el sistema al exterior  |
| `api.evd` | `ghcr.io/sistema-evaluacion-docente/api.evd` | API REST (FastAPI + PostgreSQL)                  |
| `app.evd` | `ghcr.io/sistema-evaluacion-docente/app.evd` | Frontend web (React)                             |

---

## Requisitos previos

- Un archivo `.env` con las variables de entorno configuradas

---

## Configuración

### 1. Clonar el repositorio

```bash
git clone git@github.com:sistema-evaluacion-docente/deploy.git
cd deploy
```

### 2. Crear el archivo `.env`

Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:

```env
# Puerto del reverse proxy nginx
PORT_1=80

# Base de datos
DATABASE_URL=postgresql://usuario:password@host:5432/dbname

# Redis
REDIS_URL=redis://host:6379/0

# Origenes permitidos (CORS)
ALLOWED_ORIGINS=https://tudominio.com

# Firebase Admin SDK
FIREBASE_TYPE=service_account
FIREBASE_PROJECT_ID=tu-proyecto
FIREBASE_PRIVATE_KEY_ID=clave-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@tu-proyecto.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=123456789
FIREBASE_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FIREBASE_TOKEN_URI=https://oauth2.googleapis.com/token
FIREBASE_AUTH_PROVIDER_X509_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
FIREBASE_CLIENT_X509_CERT_URL=https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk
FIREBASE_UNIVERSE_DOMAIN=googleapis.com

# Seed del admin inicial
SEED_ADMIN_INSTITUTIONAL_CODE=00000000
SEED_ADMIN_UID=firebase-uid-del-admin
SEED_ADMIN_EMAIL=admin@ufps.edu.co

# Debug (true/false)
DEBUG=false

# Modelos de HuggingFace
HUGGINGFACE_RISK_MODEL=
HUGGINGFACE_CATEGORY_MODEL=

# Firebase Client SDK (Frontend)
VITE_FIREBASE_API_KEY=tu-api-key
VITE_FIREBASE_AUTH_DOMAIN=tu-proyecto.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=tu-proyecto
VITE_FIREBASE_STORAGE_BUCKET=tu-proyecto.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789
VITE_FIREBASE_APP_ID=1:123456789:web:abcdef
```

> **Importante:** Nunca versiones el archivo `.env`. Asegúrate de que esté en `.gitignore`.

---

## Despliegue

### Iniciar servicios

```bash
docker compose up -d
```

o

```bash
podman-compose up -d
```

Este comando descarga las imágenes de los contenedores desde GitHub Container Registry (GHCR) y levanta los servicios en segundo plano. Nginx actúa como reverse proxy, exponiendo el sistema en el puerto configurado en `PORT_1`.

### Verificar estado

```bash
docker compose ps
```

o

```bash
podman-compose ps
```

### Ver logs en tiempo real

```bash
# Todos los servicios
docker compose logs -f

# Solo nginx
docker compose logs -f nginx

# Solo la API
docker compose logs -f api.evd

# Solo el frontend
docker compose logs -f app.evd
```

o

```bash
# Todos los servicios
podman-compose logs -f

# Solo nginx
podman-compose logs -f nginx

# Solo la API
podman-compose logs -f api.evd

# Solo el frontend
podman-compose logs -f app.evd
```

---

## Actualización

Para actualizar a la última versión de las imágenes:

```bash
# Descargar nuevas imágenes
docker compose pull

# Recrear los contenedores con las nuevas imágenes
docker compose up -d
```

o

```bash
# Descargar nuevas imágenes
podman-compose pull

# Recrear los contenedores con las nuevas imágenes
podman-compose up -d
```

Los contenedores anteriores se eliminan automáticamente y los nuevos toman su lugar.

---

## Detener el sistema

```bash
docker compose down
```

o

```bash
podman-compose down
```

Para eliminar también los volúmenes de datos:

```bash
docker compose down -v
```

o

```bash
podman-compose down -v
```

> **Precaución:** Esto eliminará el caché de modelos de HuggingFace almacenado en el volumen `hf_cache` y los archivos de subida almacenados en `uploads_data`. La API tardará más en la primera ejecución al volver a descargar los modelos.

---

## Recursos asignados

El servicio `api.evd` tiene los siguientes límites de recursos configurados:

| Recurso | Límite   |
| ------- | -------- |
| CPU     | 0.5 cores |
| Memoria | 1 GB     |

Estos valores están ajustados para el servidor de la UFPS. Si es necesario modificarlos, edita la sección `deploy.resources` en `docker-compose.yaml`.

---

## Volúmenes

| Volumen        | Ruta en contenedor | Descripción                                      |
| -------------- | ------------------ | ------------------------------------------------ |
| `hf_cache`     | `/app/hf_cache`    | Caché de modelos de HuggingFace                  |
| `uploads_data` | `/uploads`         | Archivos subidos por los usuarios                |

---

## Arquitectura de red

El sistema utiliza un reverse proxy **nginx** que recibe todas las peticiones entrantes y las distribuye internamente:

| Ruta         | Servicio destino | Descripción                  |
| ------------ | ---------------- | ---------------------------- |
| `/api/*`     | `api.evd:8000`   | API REST (FastAPI)           |
| `/*`         | `app.evd:80`     | Frontend web (React)         |

El frontend se configura con `VITE_API_URL=/api` para que las llamadas a la API pasen a través del mismo dominio, evitando problemas de CORS en producción.

---

## Troubleshooting

### Los contenedores no inician

```bash
# Verificar logs para identificar el error
docker compose logs nginx
docker compose logs api.evd
docker compose logs app.evd
```

o

```bash
# Verificar logs para identificar el error
podman-compose logs nginx
podman-compose logs api.evd
podman-compose logs app.evd
```

### nginx no puede conectar a los servicios

Verifica que `api.evd` y `app.evd` estén en ejecución. Si modificaste el archivo `nginx.conf`, asegúrate de que los nombres de los servicios coincidan con los definidos en `docker-compose.yaml`.

### La API no conecta a la base de datos

Verifica que la variable `DATABASE_URL` en `.env` apunte correctamente al servidor PostgreSQL y que el puerto esté accesible desde el servidor de despliegue.

### Los modelos de IA tardan en cargar

La primera vez que inicia `api.evd`, los modelos de HuggingFace se descargan y se almacenan en el volumen `hf_cache`. En ejecuciones posteriores se cargan desde caché.

### Error de autenticación Firebase

Asegúrate de que todas las variables `FIREBASE_*` estén correctamente configuradas y que la cuenta de servicio tenga los permisos necesarios en Firebase Console.

### Reiniciar un servicio específico

```bash
docker compose restart nginx
docker compose restart api.evd
docker compose restart app.evd
```

o

```bash
podman-compose restart nginx
podman-compose restart api.evd
podman-compose restart app.evd
```

---

## Repositorios relacionados

| Repositorio | Descripción                             | URL                                                                                                    |
| ----------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| api.evd     | API REST (FastAPI)                      | [github.com/sistema-evaluacion-docente/api.evd](https://github.com/sistema-evaluacion-docente/api.evd) |
| app.evd     | Frontend web (React)                    | [github.com/sistema-evaluacion-docente/app.evd](https://github.com/sistema-evaluacion-docente/app.evd) |
| deploy      | Configuración de despliegue (este repo) | [github.com/sistema-evaluacion-docente/deploy](https://github.com/sistema-evaluacion-docente/deploy)   |

---

## Autores

| Autor              | Correo                                                                    |
| ------------------ | ------------------------------------------------------------------------- |
| Andrés Parra       | [andresalfonsopg@ufps.edu.co](mailto:andresalfonsopg@ufps.edu.co)         |
| Orlando Beltrán    | [orlandojosebv@ufps.edu.co](mailto:orlandojosebv@ufps.edu.co)             |
| Alessandro Daniele | [alessandroumbertods@ufps.edu.co](mailto:alessandroumbertods@ufps.edu.co) |
