-- 1. Представление: Карточка тура
-- expect: rows 3
SELECT * FROM v_tour_cards WHERE tour_id <= 3;

-- 2. Представление: Сводка броней
SELECT * FROM v_tour_bookings_summary WHERE total_seats_booked > 0 LIMIT 5;

-- 3. Функция свободных мест
-- expect: rows 1
SELECT free_seats(1) AS free_seats_for_tour_1;

-- 4. Бизнес-операция бронирования
BEGIN;
SELECT book_tour(1, 1, 2) AS new_booking_id;
SELECT * FROM bookings WHERE id = (SELECT max(id) FROM bookings);
ROLLBACK;

-- 5. Нарушение правила: Отзыв на тур, который ещё не закончился
BEGIN;
-- Искусственно делаем тур 1 будущим (чтобы триггер точно сработал)
UPDATE tours SET ends_at = now() + interval '10 days' WHERE id = 1;
-- Пытаемся оставить отзыв
-- expect: error "Нельзя оставить отзыв"
INSERT INTO reviews (client_id, tour_id, rating, comment) 
VALUES (1, 1, 5, 'Отличный тур!');
ROLLBACK;

-- 6. Успешный отзыв (искусственно делаем тур прошедшим)
BEGIN;
-- Делаем тур 2 прошедшим
UPDATE tours SET ends_at = now() - interval '1 day' WHERE id = 2;
-- Вставляем отзыв (должно пройти без ошибок)
INSERT INTO reviews (client_id, tour_id, rating, comment) 
VALUES (1, 2, 4, 'Хороший тур, но был дождь.');
SELECT * FROM reviews WHERE tour_id = 2;
ROLLBACK;

-- 7. Служебный триггер updated_at
BEGIN;
SELECT id, updated_at FROM tours WHERE id = 1;
UPDATE tours SET price = price + 1000 WHERE id = 1;
SELECT id, updated_at FROM tours WHERE id = 1;
ROLLBACK;

-- 8. Материализованное представление
REFRESH MATERIALIZED VIEW mv_revenue_monthly;
SELECT * FROM mv_revenue_monthly LIMIT 3;

-- 9. Функция поиска
SELECT * FROM search_tours('Турция', 50000);

-- 10. Журнал изменений
SELECT operation, changed_by, changed_at FROM tours_audit;

-- 11. Состояние на дату
SELECT tour_state_at(1, now());