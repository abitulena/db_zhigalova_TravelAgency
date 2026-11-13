-- Лаба 2. Запросы к базе «Турагентство».

-- 1. Какие отели находятся в Турции? (JOIN)
SELECT h.name, h.stars, c.name AS country
FROM hotels h
JOIN countries c ON c.id = h.country_id
WHERE c.name = 'Турция';

-- 2. Какие туры длятся больше 7 дней? (JOIN, вычисляемое поле)
SELECT t.title, h.name AS hotel, t.starts_at, t.ends_at,
       (t.ends_at::date - t.starts_at::date) AS days
FROM tours t
JOIN hotels h ON h.id = t.hotel_id
WHERE (t.ends_at::date - t.starts_at::date) > 7;

-- 3. Список всех броней с клиентом, туром и отелем (JOIN 4 таблицы)
SELECT b.id AS booking_id, cl.full_name, t.title, h.name AS hotel, b.seats
FROM bookings b
JOIN clients cl ON cl.id = b.client_id
JOIN tours t ON t.id = b.tour_id
JOIN hotels h ON h.id = t.hotel_id
ORDER BY b.id;

-- 4. Сколько туров в каждом отеле? (GROUP BY + COUNT)
SELECT h.name AS hotel, count(t.id) AS tours_count
FROM hotels h
LEFT JOIN tours t ON t.hotel_id = h.id
GROUP BY h.id, h.name
ORDER BY tours_count DESC;

-- 5. В каких странах больше 1 отеля? (GROUP BY + HAVING)
SELECT c.name AS country, count(h.id) AS hotels_count
FROM countries c
JOIN hotels h ON h.country_id = c.id
GROUP BY c.id, c.name
HAVING count(h.id) > 1;

-- 6. Какие клиенты не сделали ни одной брони? (LEFT JOIN + IS NULL)
-- ON CONFLICT DO NOTHING защищает от ошибки, если сирота уже есть в базе
BEGIN;
INSERT INTO clients (email, full_name) 
VALUES ('orphan@lab2.ru', 'Клиент без брони')
ON CONFLICT (email) DO NOTHING;

SELECT cl.full_name, cl.email
FROM clients cl
LEFT JOIN bookings b ON b.client_id = cl.id
WHERE b.id IS NULL;
ROLLBACK;

-- 7. Какие туры не были забронированы ни разу? (LEFT JOIN + IS NULL)
SELECT t.title
FROM tours t
LEFT JOIN bookings b ON b.tour_id = t.id
WHERE b.id IS NULL;

-- 8. Туры с ценой выше средней по всем турам (подзапрос)
SELECT title, price
FROM tours
WHERE price > (SELECT avg(price) FROM tours);

-- 9. Клиенты, у которых есть хотя бы одна бронь (подзапрос EXISTS)
SELECT cl.full_name
FROM clients cl
WHERE EXISTS (
    SELECT 1 FROM bookings b WHERE b.client_id = cl.id
);

-- 10. Какие туры относятся к тегу «пляж»? (подзапрос IN)
SELECT t.title
FROM tours t
WHERE t.id IN (
    SELECT l.tour_id
    FROM tour_tag_links l
    JOIN tour_tags tg ON tg.id = l.tag_id
    WHERE tg.name = 'пляж'
);

-- 11. Обновляем цену: туры дороже 100000 получают скидку 10%
BEGIN;
-- До обновления
SELECT id, title, price FROM tours WHERE price > 100000 ORDER BY id;
-- Обновление
UPDATE tours SET price = price * 0.9 WHERE price > 100000;
-- После обновления
SELECT id, title, price FROM tours WHERE price > 100000 ORDER BY id;
ROLLBACK;

-- 12. Удаляем все брони клиента, у которого они точно есть (с проверкой до и после)
BEGIN;
-- До удаления: выбираем конкретного клиента, у которого есть бронь
SELECT id, client_id, tour_id 
FROM bookings 
WHERE client_id = (SELECT client_id FROM bookings LIMIT 1);

-- Удаление: удаляем брони именно этого клиента
DELETE FROM bookings 
WHERE client_id = (SELECT client_id FROM bookings LIMIT 1);

-- После удаления: проверяем, что у него больше нет броней
SELECT id, client_id, tour_id 
FROM bookings 
WHERE client_id = (SELECT client_id FROM bookings ORDER BY random() LIMIT 1);
ROLLBACK;

-- 13. ★: Топ-3 тура по цене в каждом отеле + накопительная сумма
WITH ranked AS (
    SELECT h.name AS hotel, t.title, t.price,
           ROW_NUMBER() OVER (PARTITION BY h.id ORDER BY t.price DESC) AS rn,
           SUM(t.price) OVER (PARTITION BY h.id ORDER BY t.price DESC) AS running_total
    FROM tours t
    JOIN hotels h ON h.id = t.hotel_id
)
SELECT hotel, title, price, running_total, rn
FROM ranked
WHERE rn <= 3
ORDER BY hotel, rn;

-- 14. ★★: Помесячная динамика бронирований и процент к прошлому месяцу
WITH monthly AS (
    SELECT date_trunc('month', created_at)::date AS month,
           count(*) AS bookings_count
    FROM bookings
    GROUP BY month
)
SELECT month,
       bookings_count,
       LAG(bookings_count) OVER (ORDER BY month) AS prev_month_count,
       round(
           100.0 * (bookings_count - LAG(bookings_count) OVER (ORDER BY month)) 
           / NULLIF(LAG(bookings_count) OVER (ORDER BY month), 0), 
           1
       ) AS pct_change
FROM monthly
ORDER BY month;

-- 15. ★★: Рекурсивный CTE для генерации календаря на 10 дней
WITH RECURSIVE calendar AS (
    SELECT '2026-06-01'::date AS day
    UNION ALL
    SELECT day + 1 FROM calendar WHERE day < '2026-06-10'
)
SELECT day FROM calendar;