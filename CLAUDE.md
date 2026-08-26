# CLAUDE.md

Guidance for Claude Code (and other AI assistants) working in this repository.

## What this repo is

**GroceryMate** — a full-stack e-commerce (online grocery shopping) platform:
- `backend/` — Flask + PostgreSQL REST API, serving the built React app as static files.
- `frontend/` — Create React App (CRA) single-page app, plain CSS + Tailwind.
- `infrastructure/` — Terraform stub for AWS deployment (`main.tf` is currently empty —
  infra is not actually defined here yet; don't assume Terraform resources exist).

The current git branch checked out locally is `version2` upstream / a `claude/...`
working branch — check `git branch` / `git status` before assuming which branch you're on.

## Architecture

### Backend (`backend/app`) — layered Flask app

```
routes/      -> controllers/   -> services/        -> models/
(URL + verb)    (request/response,  (business logic,     (SQLAlchemy models)
                 status codes)       DB queries)
```

- `routes/*_routes.py` define Flask `Blueprint`s and map URLs to controller functions.
  Blueprints registered in `app/__init__.py::create_app()`: `auth_bp`, `user_bp`,
  `product_bp`, `health_bp`, `config_bp`.
- `controllers/*_controller.py` parse the request, call into `services/`, handle
  errors, and return `jsonify(...)` with an HTTP status code. They should not contain
  raw SQLAlchemy queries.
- `services/*_service.py` hold the actual business logic and DB access.
- `models/*_model.py` are SQLAlchemy models (`db.Model`), each with a `to_dict()` for
  JSON serialization. Current models: `Product`, `Review` (in `product_model.py`),
  and user-related models in `user_model.py`.
- `middleware/`, `utils/`, `helpers.py` — cross-cutting helpers.
- `testing/` — currently just an empty package (`__init__.py`); **there is no
  meaningful automated test suite in this repo today**. Don't assume `pytest` will
  find real tests here.

When adding a feature, follow the existing pattern: new route → new/extended
controller → new/extended service → model changes if needed, plus a matching
Flask-Migrate migration (see below).

### App bootstrap (`backend/app/__init__.py`)

- `create_app()` wires CORS (wide open, `origins: "*"`), `SQLAlchemy`, `JWTManager`
  (`flask_jwt_extended`), `Flask-Migrate`, blueprint registration, file logging
  (rotating log in `logs/app.log`), and a catch-all route that serves the built React
  app (`frontend/build`) for any non-API path (SPA fallback).
- `fetch_frontend()` — on startup, if `frontend/build` is missing or stale, it
  **downloads the latest frontend build as a zip from this repo's GitHub Releases**
  (`AlejandroRomanIbanez/AWS_grocery` releases, asset `frontend-build.zip`) and
  extracts it into `frontend/build`. This means: the backend does not require you to
  `npm run build` locally to boot, but it does mean the served frontend can be stale
  relative to your `frontend/src` changes unless a new release/build artifact exists.
  If you're actively developing the frontend, run it separately with `npm start`
  (CRA dev server) rather than relying on the Flask-served build.
- `Config.is_rds()` / `is_local_postgres()` distinguish AWS RDS (production) from a
  local/Docker Postgres by sniffing `POSTGRES_URI` for an `amazonaws.com` hostname.
  `manage.py` uses this to skip auto-migrations against RDS.

### Database

- PostgreSQL only (`psycopg2-binary`); no SQLite support despite the seed file being
  named `sqlite_dump_clean.sql` (it's plain SQL run via `psql`/psycopg2, not sqlite).
- Schema/data managed via `Flask-Migrate` (Alembic). `backend/manage.py` is the
  entrypoint used to: wait for the DB (`wait_for_db()`), auto-initialize migrations if
  none exist, `upgrade()`, and seed data from `app/sqlite_dump_clean.sql` (products
  inserted first, then everything else, tolerating duplicate/FK errors on re-seed).
- Local dev DB setup and seeding commands are in `README.md` (`psql ... -f
  backend/app/sqlite_dump_clean.sql`).

### Frontend (`frontend/src`)

- CRA app (`react-scripts`), React 16, React Router v6.
- `Component/` holds one folder per feature/page (`Auth`, `Checkout`, `Header`,
  `Home`, `ProductStore`, `ProductDetail`, `Navbar`, `Footer`, `Search`, `Brands`,
  `Skeleton`, `AgeVerification`, ...), each typically pairing a `.js` component with a
  co-located `.css` file. Follow this co-location convention for new components.
- `hooks/useUserInfo.js` — shared auth/user-info hook.
- `config.js` — reads `REACT_APP_BACKEND_SERVER` env var for the API base URL.
- `ProtectedRoute.js` — route guard for authenticated-only pages.
- Stray editor backup files (`*.js~`, `index.html~`) exist in the tree (e.g.
  `AvatarModal.js~`, `ProductStore.js~`) — these are leftover swap files, not real
  source; don't edit them, and feel free to remove them if you're touching that area
  and the user confirms it's safe (they're not referenced by the build).
- Tailwind is configured (`tailwind.config.js`) alongside plain CSS files; don't
  assume the whole app has been migrated to Tailwind classes.

## Environment / configuration

Both `backend/.env.example` and `frontend/.env.example` show the required variables:

**Backend `.env`:**
```
JWT_SECRET_KEY=<generate with: python3 -c "import secrets; print(secrets.token_hex(32))">
FLASK_ENV=development
POSTGRES_USER=...
POSTGRES_PASSWORD=...
POSTGRES_DB=...
POSTGRES_HOST=...
POSTGRES_URI=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}
```

**Frontend `.env`:**
```
REACT_APP_BACKEND_SERVER=<backend URL, e.g. http://localhost:5000>
```

Never commit real `.env` files or secrets — only `.env.example` should be tracked.
Note the `backend/Dockerfile` currently does `COPY .env .env`, which means a real
`.env` must exist at build time for that Docker image to work as written; treat this
as existing (imperfect) behavior rather than something to silently "fix" without
flagging it, since removing it would change how the image is built.

## Running locally

Backend (see `README.md` for full Postgres setup):
```sh
cd backend
pip install -r requirements.txt
python3 run.py        # dev server on http://localhost:5000, debug=True
# or, to run migrations + seed data first:
python manage.py
```

Frontend:
```sh
cd frontend
npm install
npm start              # CRA dev server, proxies to REACT_APP_BACKEND_SERVER
npm run build           # production build (what create_app() also fetches from Releases)
npm test                 # react-scripts test (jest + testing-library)
```

There is no `docker-compose.yml` in the repo despite a `Dockerfile` existing for the
backend — running the full stack today means running Postgres, backend, and frontend
as separate local processes per the README, not `docker compose up`.

## Conventions / notes for future changes

- **Layering**: keep DB/query logic in `services/`, not `controllers/`. Controllers
  should stay thin (validate input, call service, map exceptions to status codes).
- **Logging**: use `current_app.logger` inside controllers/services, matching
  existing calls (`current_app.logger.info/error(...)`), not bare `print()`.
- **JWT auth**: protected endpoints use `@jwt_required()` and `get_jwt_identity()`
  from `flask_jwt_extended`, following `product_controller.py`'s pattern.
- **Docstrings**: existing controller functions use full docstrings (Args/Returns).
  Match this style for new controller/service functions.
- **No CI config exists** (no `.github/workflows`). There's no linting/formatting
  pipeline enforced automatically — `pylint`/`isort` are listed as backend deps but
  not wired into any script; run them manually if asked to lint.
- **`requirements.txt` encoding**: the file is UTF-16 encoded (not plain UTF-8/ASCII).
  If editing it by hand with tools that assume UTF-8, verify the encoding is preserved
  or re-save as UTF-16 — otherwise `pip install -r requirements.txt` may misparse it.
- **`infrastructure/main.tf` is empty.** Don't assume any Terraform-managed AWS
  resources are defined; if asked to add infra, you're starting from scratch here.
- Avatar images are stored on-disk under `backend/avatar/` and served/managed via the
  user controller/service — treat this as local file storage, not S3, unless infra
  is added to change that.
