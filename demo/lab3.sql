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

-- 5. Нарушение правила триггером (прямой INSERT на 15 мест)
-- expect: error "Превышен лимит"
BEGIN;
INSERT INTO bookings (client_id, tour_id, seats) VALUES (1, 2, 15);
ROLLBACK;

-- 6. Служебный триггер updated_at
BEGIN;
SELECT id, updated_at FROM tours WHERE id = 1;
UPDATE tours SET price = price + 1000 WHERE id = 1;
SELECT id, updated_at FROM tours WHERE id = 1;
ROLLBACK;

-- 7. Материализованное представление
REFRESH MATERIALIZED VIEW mv_revenue_monthly;
SELECT * FROM mv_revenue_monthly LIMIT 3;

-- 8. Функция поиска
SELECT * FROM search_tours('Турция', 50000);
SELECT * FROM search_tours();

-- 9. Журнал изменений
SELECT operation, changed_by, changed_at FROM tours_audit;

-- 10. Состояние на дату
SELECT tour_state_at(1, now());