-- Лаба 1. Сценарий для показа.

-- 1. Таблицы на месте: 7 таблиц
-- expect: rows 7
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY 1;

-- 2. Повтор email: ошибка UNIQUE
-- expect: error unique
INSERT INTO clients (email, full_name) VALUES ('ivanov@mail.ru', 'Дубль');

-- 3. Отрицательная цена: ошибка CHECK
-- expect: error check
INSERT INTO tours (hotel_id, title, starts_at, ends_at, price)
VALUES (1, 'Плохой тур', now(), now() + interval '7 days', -100);

-- 4. Несуществующий тур: ошибка FK
-- expect: error fk
INSERT INTO bookings (client_id, tour_id, seats) VALUES (1, 99999, 1);