-- [setup] Фиксируем цену тура 1
UPDATE tours SET price = 85000 WHERE id = 1;

-- [A] Окно A, первое чтение
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT price::int FROM tours WHERE id = 1;
-- expect: value 85000

-- [B] Окно B меняет цену и коммитит
BEGIN;
UPDATE tours SET price = 90000 WHERE id = 1;
COMMIT;

-- [A] Окно A, второе чтение — видит новое значение
SELECT price::int FROM tours WHERE id = 1;
-- expect: value 90000
COMMIT;

-- [cleanup]
UPDATE tours SET price = 85000 WHERE id = 1;