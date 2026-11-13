-- Добавляем колонку updated_at для служебного триггера
ALTER TABLE tours ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();

-- 1. Представление: Карточка тура
-- Частый запрос: показать тур, отель, страну и звёздность отеля
CREATE VIEW v_tour_cards AS
SELECT 
    t.id AS tour_id, 
    t.title AS tour_title, 
    t.price, 
    h.name AS hotel_name, 
    h.stars, 
    c.name AS country_name
FROM tours t
JOIN hotels h ON h.id = t.hotel_id
JOIN countries c ON c.id = h.country_id;

-- 2. Представление: Сводка по броням
-- Частый запрос: сколько всего мест забронировано на каждый тур
CREATE VIEW v_tour_bookings_summary AS
SELECT 
    t.id AS tour_id,
    t.title,
    count(b.id) AS total_bookings,
    coalesce(sum(b.seats), 0) AS total_seats_booked
FROM tours t
LEFT JOIN bookings b ON b.tour_id = t.id
GROUP BY t.id, t.title;

CREATE MATERIALIZED VIEW mv_revenue_monthly AS
SELECT 
    date_trunc('month', created_at)::date AS month,
    count(*) AS total_bookings,
    sum(b.seats * t.price) AS revenue
FROM bookings b
JOIN tours t ON t.id = b.tour_id
GROUP BY month
ORDER BY month;