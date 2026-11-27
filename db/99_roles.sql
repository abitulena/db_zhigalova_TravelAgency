-- Лаба 4. Роли и права доступа
-- Пароли берутся из переменных окружения (docker-compose передаёт их из .env)

\getenv reader_password APP_READER_PASSWORD
\getenv writer_password APP_WRITER_PASSWORD
\getenv client_password APP_CLIENT_PASSWORD

-- Проверка: переменные заданы
\if :{?reader_password}
\else
    \echo 'APP_READER_PASSWORD не задан в .env'
    \quit 1
\endif

\if :{?writer_password}
\else
    \echo 'APP_WRITER_PASSWORD не задан в .env'
    \quit 1
\endif

\if :{?client_password}
\else
    \echo 'APP_CLIENT_PASSWORD не задан в .env'
    \quit 1
\endif

-- Идемпотентное создание ролей
SELECT format('CREATE ROLE app_reader LOGIN PASSWORD %L', :'reader_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_reader')
\gexec

SELECT format('CREATE ROLE app_writer LOGIN PASSWORD %L', :'writer_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_writer')
\gexec

SELECT format('CREATE ROLE app_client LOGIN PASSWORD %L', :'client_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_client')
\gexec

GRANT app_reader TO app_writer;

-- Забираем права у PUBLIC
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC;
REVOKE EXECUTE ON ALL ROUTINES IN SCHEMA public FROM PUBLIC;

-- app_reader: только чтение представлений и read-only функции
GRANT USAGE ON SCHEMA public TO app_reader;
GRANT SELECT ON v_tour_cards, v_tour_bookings_summary TO app_reader;
GRANT SELECT ON mv_revenue_monthly TO app_reader;
GRANT EXECUTE ON FUNCTION free_seats(integer) TO app_reader;

-- app_writer: ничего на таблицы, только бизнес-операция
GRANT USAGE ON SCHEMA public TO app_writer;

-- app_client: только для теста RLS (чтение bookings с политикой)
GRANT USAGE ON SCHEMA public TO app_client;
GRANT SELECT ON bookings TO app_client;

-- Безопасная функция бронирования
CREATE OR REPLACE FUNCTION book_tour_safe(
    p_client_id integer,
    p_tour_id   integer,
    p_seats     integer
) RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_booking_id integer;
    v_booked     integer;
    v_limit      integer := 10;  -- тот же лимит, что в free_seats
BEGIN
    PERFORM 1 FROM tours WHERE id = p_tour_id FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Тур % не найден', p_tour_id;
    END IF;

    SELECT coalesce(sum(seats), 0) INTO v_booked
    FROM bookings WHERE tour_id = p_tour_id;

    IF v_limit - v_booked < p_seats THEN
        RAISE EXCEPTION 'Недостаточно мест. Свободно: %, запрошено: %',
            v_limit - v_booked, p_seats;
    END IF;

    INSERT INTO bookings (client_id, tour_id, seats)
    VALUES (p_client_id, p_tour_id, p_seats)
    RETURNING id INTO v_booking_id;

    RETURN v_booking_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION book_tour_safe(integer, integer, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION book_tour_safe(integer, integer, integer) TO app_writer;