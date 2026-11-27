INSERT INTO clients (email, full_name)
SELECT 'client' || g || '@example.com', 'Клиент ' || g
FROM generate_series(1, 2000) g;

INSERT INTO bookings (client_id, tour_id, seats, created_at)
SELECT
    (SELECT id FROM clients ORDER BY random() LIMIT 1),
    (SELECT id FROM tours   ORDER BY random() LIMIT 1),
    1 + (random() * 3)::int,
    now() - (random() * interval '365 days')
FROM generate_series(1, 2000);

-- Генерируем отзывы (для лабы 1, чтобы было 10+ строк)
INSERT INTO reviews (client_id, tour_id, rating, comment, created_at)
SELECT 
    c.id, 
    t.id, 
    (1 + (random() * 4)::int), -- рейтинг от 1 до 5
    'Отзыв на тур ' || t.title,
    now() - (random() * interval '365 days')
FROM clients c
CROSS JOIN (SELECT id, title FROM tours LIMIT 10) t
LIMIT 2000;