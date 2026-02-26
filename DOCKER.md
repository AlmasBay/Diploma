# Docker setup

## 1) Requirements

- Docker Desktop installed and running.

## 2) Run backend + database (recommended for mobile app)

From repository root:

```powershell
docker compose up -d --build db newsapp
```

Check containers:

```powershell
docker compose ps
```

Backend API will be available on:

- `http://localhost:8080`
- `http://<your_pc_lan_ip>:8080` (for physical phone in same Wi-Fi)

Stop:

```powershell
docker compose down
```

Stop and remove DB volume:

```powershell
docker compose down -v
```

## 3) Run web frontend in Docker (optional)

`infohub_web` is behind profile `web`:

```powershell
docker compose --profile web up -d --build
```

Open in browser:

- `http://localhost:3000`

API requests `/api/*` are proxied to backend container automatically.

## 4) Mobile app API URL behavior

Flutter app now supports build-time API URL:

- key: `API_BASE_URL`
- default: `http://172.20.10.2:8080/api` (your current value, unchanged for normal mobile runs)

Examples:

```powershell
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api

# Physical phone (replace with your PC LAN IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8080/api
```
