#!/usr/bin/env bash
set -euo pipefail

# Дамп в кастомном формате
docker compose exec -T db pg_dump -U postgres -d app -Fc -f /tmp/app.dump
docker compose cp db:/tmp/app.dump ./app.dump

# Восстановление в чистую базу
docker compose exec -T db createdb -U postgres app_restore
docker compose cp ./app.dump db:/tmp/app.dump
docker compose exec -T db pg_restore -U postgres -d app_restore /tmp/app.dump

# Проверка: количество строк совпадает
docker compose exec -T db psql -U postgres -d app_restore -c \
  "SELECT count(*) FROM bookings;"