-- Run once if your database was created before the default admin was added to schema.sql:
--   psql "$DATABASE_URL" -f seed_default_admin.sql
--
-- Default admin: admin.smartcampus@gmail.com / AdminSmartCampus2026!

INSERT INTO users (name, email, password, is_admin)
VALUES (
  'Campus Admin',
  'admin.smartcampus@gmail.com',
  '$2a$10$SksXRvGFW6Vupouf237CRubSU80FGgTEGP1ymguIGvjA/TIid6fdK',
  true
)
ON CONFLICT (email) DO UPDATE SET
  is_admin = true;
