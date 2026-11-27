-- [setup] То же самое: 9 мест занято, 1 свободно
DELETE FROM bookings WHERE tour_id = 2;
INSERT INTO bookings (client_id, tour_id, seats, created_at)
SELECT 1, 2, 9, '2026-01-01 00:00+03';

-- [A] Окно A: безопасная функция блокирует строку тура
SET ROLE app_writer;
BEGIN;
SELECT book_tour_safe(2, 2, 1);

-- [B] Окно B: пытается то же самое — блокируется до коммита A
SET ROLE app_writer;
BEGIN;
SELECT book_tour_safe(3, 2, 1);
-- expect: blocked

-- [A]
COMMIT;

-- [B] После коммита A функция B видит, что мест нет. Транзакция в состоянии ошибки, откатываем её.
ROLLBACK;

-- [check] Продано не больше, чем лимит (10)?
-- expect: true
SELECT coalesce(sum(seats), 0) <= 10
FROM bookings WHERE tour_id = 2;

-- [cleanup]
RESET ROLE;
DELETE FROM bookings WHERE tour_id = 2;