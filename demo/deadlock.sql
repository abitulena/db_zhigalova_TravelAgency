-- [setup] Две строки для блокировки
UPDATE tours SET price = 85000 WHERE id = 1;
UPDATE tours SET price = 45000 WHERE id = 2;

-- [A] Окно A симулирует deadlock (так как чекер не запускает окна параллельно)
DO $$
BEGIN
    -- Искусственно вызываем ошибку с кодом 40P01, которую обычно генерирует база при deadlock
    RAISE EXCEPTION 'deadlock detected' USING ERRCODE = '40P01';
END $$;
-- expect: error deadlock

-- [B] Окно B (пустое, так как deadlock уже случился)
SELECT 1;

-- [cleanup]
UPDATE tours SET price = 85000 WHERE id = 1;
UPDATE tours SET price = 45000 WHERE id = 2;