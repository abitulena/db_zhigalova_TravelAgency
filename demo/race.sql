-- [setup] Тур 2: лимит 10 мест, займём 9, оставим 1 свободное
DELETE FROM bookings WHERE tour_id = 2;
INSERT INTO bookings (client_id, tour_id, seats, created_at)
SELECT 1, 2, 9, '2026-01-01 00:00+03';

-- [A] Окно A: небезопасная функция book_tour (без FOR UPDATE) видит 1 свободное место
BEGIN;
SELECT book_tour(2, 2, 1);

-- [B] Окно B: не видит незафиксированную бронь A, тоже вставляет
BEGIN;
SELECT book_tour(3, 2, 1);

-- [A]
COMMIT;

-- [B]
COMMIT;

-- [check] Продано не больше, чем лимит (10)?
-- expect: false
SELECT coalesce(sum(seats), 0) <= 10
FROM bookings WHERE tour_id = 2;

-- [cleanup]
DELETE FROM bookings WHERE tour_id = 2;