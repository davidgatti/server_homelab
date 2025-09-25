# HomeLab Services APIs

## True REST APIs (Programmatic Access)

- **Qdrant** - `http://qdrant.lan/collections` - Vector database REST API (No auth) ✅
- **N8N** - `http://n8n.lan/api/v1/workflows` - Workflow automation API (X-N8N-API-KEY header) ✅
- **Home Assistant** - `http://homeassistant.lan/api/` - Smart home REST API (Bearer Token) ✅
- **Jellyfin** - `http://jellyfin.lan:8096/api` - Media server API (API Key) ✅
- **Docmost** - `http://docmost.lan/api/` - Documentation platform API (Bearer Token) ✅
- **Alertmanager** - `http://alertmanager.lan/api/v2/status` - Alert management API (No auth) ✅
- **Prometheus** - `http://prometheus.lan/api/v1/label/__name__/values` - Time series database API (No auth) ✅
- **Grafana** - `http://grafana.lan/api/health` - Visualization platform API (API Key/Session) ✅
- **Loki** - `http://loki.lan:3100/loki/api/v1/labels` - Log aggregation API (No auth) ✅
- **Paperless** - `http://paperless.lan:8000/api/` - Document management API (Token Auth) ✅ (redirects to schema)
- **Metabase** - `http://metabase.lan/api/health` - Business intelligence API (Session Auth) ✅
- **NocoDB** - `http://nocodb.lan/api/v1/db/meta/projects` - No-code database API (JWT Token) ✅

- **Tika** - `http://tika:9998/tika` - Content extraction API (No auth) ✅ (no .lan DNS)
- **Gotenberg** - `http://gotenberg:3000/forms/chromium/convert/html` - PDF generation API (No auth) ✅ (no .lan DNS)