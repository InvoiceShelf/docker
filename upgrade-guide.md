# Important Notice: Docker Image & Compose Changes (as of `2.2.0-alpha1` and 2025-09-01 Nightly Builds)

Hello,

Starting with **InvoiceShelf `2.2.0-alpha1`** and the **2025-09-01 nightly builds**, we’ve made significant changes to the Docker image and how storage is handled. These updates fix longstanding issues with the old image and align the project with modern Laravel/Docker best practices.

---

## ✅ New Base Image

We now use **`serversideup/php:8.3-fpm-nginx-alpine`** as the base image.

- Tuned for Laravel workloads
- Proper PHP configuration out of the box
- Multi-platform
- Easier to maintain than a custom-built base

---

## 📂 Storage Changes

The old images created a `/data` directory, duplicating Laravel’s `storage` (`/var/www/html/storage`) and symlinking back. This led to permission and consistency issues.

- **Old:** `/data` (bind-mounted from `./invoiceshelf/data`)
- **New:** Use Laravel’s default path **`/var/www/html/storage`** directly

**Action:** Update your `docker-compose.yml` to mount your local `./invoiceshelf/data` to `/var/www/html/storage` (instead of `/data`).

```yaml
# New compose (snippet)
services:
  webapp:
    volumes:
      - ./invoiceshelf/data:/var/www/html/storage
```

---

## 🗄️ SQLite Path Changes (Action required if you use SQLite)

If you use the **SQLite variant**:

- **Old host path:** `invoiceshelf/conf/database.sqlite`
- **New host path:** `invoiceshelf/data/app/database.sqlite`
- **Container path (env):** `/var/www/html/storage/app/database.sqlite`

**Copy the file from the old path to the new path**, then update your environment:

```bash
# From your Compose project root:
mkdir -p invoiceshelf/data/app
cp invoiceshelf/conf/database.sqlite invoiceshelf/data/app/database.sqlite
```

```env
DB_CONNECTION=sqlite
DB_DATABASE=/var/www/html/storage/app/database.sqlite
```

> If you used a slightly different folder name, adjust the paths accordingly.

---

## ⚙️ Removal of `/conf`

The `/conf` directory is no longer part of the container.

- `.env` is generated at startup from environment variables.
- SQLite databases are expected under `/var/www/html/storage/app/`.
- Starting with **2.2.0 proper**, **mail configuration** moves into the **database** (no longer set in `docker-compose.yml`).

---

## 🆕 Docker Compose Changes

### **OPTIONAL (Recommended): Switch to a Docker _named volume_ for storage**

Instead of mounting a host path, you can let Docker manage the storage location via a **named volume** (reduces host-permission issues).

**Old compose (host bind mounts):**
```yaml
volumes:
  - ./invoiceshelf_sqlite/data:/data
  - ./invoiceshelf_sqlite/conf:/conf
```

**New compose (Docker named volume):**
```yaml
services:
  webapp:
    volumes:
      - invoiceshelf_storage:/var/www/html/storage

volumes:
  invoiceshelf_storage:
```

If you want to **migrate existing storage** into the named volume:

1) Create and inspect the volume:
```bash
docker volume create {compose_project}_invoiceshelf_storage
docker volume inspect {compose_project}_invoiceshelf_storage
```

Where `{compose_project}` is the name of your directory where the docker compose is located. If you cloned this repository it will be `docker`.

2) Copy your current storage content into the volume

> If you prefer, you can also start the container once and use `docker cp` to move files into `/var/www/html/storage`.

---

## 🧰 Legacy Docker Images (Optional fallback)

For users who prefer to keep the previous Docker behavior, we’ve published **legacy tags**:

- `invoiceshelf/invoiceshelf:2.1.1-legacy`
- `invoiceshelf/invoiceshelf:latest-legacy`

> These tags point to the legacy image compatible with the old layout and compose patterns. To use them, simply change the image tag in your `docker-compose.yml`, for example:

```yaml
services:
  webapp:
    image: invoiceshelf/invoiceshelf:latest-legacy
    # or pin a specific legacy version:
    # image: invoiceshelf/invoiceshelf:2.1.1-legacy
```

---

## 🔑 Entrypoint Simplification

The entrypoint script is much simpler now:

- No `/data` or `/conf` handling
- `.env` is created on first start (values injected from env vars)
- SQLite DB created under `/var/www/html/storage/app/` if missing
- Leaner, more reliable permissions handling

---

## 📖 Reference

Full diff between the old and new docker-compose setups:  
[Compare on GitHub](https://github.com/InvoiceShelf/docker/compare/52541f9be8655c0c8c8122e3211fd88328ebd3a7...8862f982627de0aaf84f3be93995638ae07e5397#diff-284b7f4fe53b6cafa3fff93701a8f5b709c42e71c8f36a1757d8cb33068b273d)

---

Best regards,  
**Darko**
