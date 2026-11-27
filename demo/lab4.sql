-- 1. Фиксируем исходное значение (это шаг 1)
-- expect: value 85000
SELECT price::int FROM tours WHERE id = 1;

-- 2. Транзакция падает на середине
BEGIN;
UPDATE tours SET price = price + 100 WHERE id = 1;
UPDATE tours SET price = -1 WHERE id = 1;
-- expect: error check
COMMIT;

-- 3. Проверяем, что данные не изменились (сравниваем с шагом 1)
-- expect: same 1
SELECT price::int FROM tours WHERE id = 1;

-- 4. app_reader не может менять таблицу
SET ROLE app_reader;
UPDATE tours SET price = 1 WHERE id = 1;
-- expect: error permission
RESET ROLE;

-- 5. app_reader не может читать таблицу
SET ROLE app_reader;
SELECT * FROM tours LIMIT 1;
-- expect: error permission
RESET ROLE;

-- 6. app_writer не может вставлять напрямую
SET ROLE app_writer;
INSERT INTO bookings (client_id, tour_id, seats) VALUES (1, 2, 1);
-- expect: error permission
RESET ROLE;

-- 7. app_writer может вызвать book_tour_safe
SET ROLE app_writer;
BEGIN;
SELECT book_tour_safe(1, 2, 1);
ROLLBACK;
-- expect: rows 1
RESET ROLE;