-- 1. Триггерная функция: проверка правила "Не больше 10 мест на тур"
CREATE FUNCTION check_seats_limit() RETURNS trigger 
LANGUAGE plpgsql AS $$
DECLARE
    v_total_booked integer;
BEGIN
    SELECT coalesce(sum(seats), 0) INTO v_total_booked 
    FROM bookings 
    WHERE tour_id = NEW.tour_id AND id != coalesce(NEW.id, -1);

    IF v_total_booked + NEW.seats > 10 THEN
        RAISE EXCEPTION 'Превышен лимит мест на тур. Уже забронировано: %', v_total_booked;
    END IF;
    
    RETURN NEW;
END $$;

CREATE TRIGGER trg_check_seats_limit 
BEFORE INSERT OR UPDATE ON bookings
FOR EACH ROW EXECUTE FUNCTION check_seats_limit();

-- 2. Служебный триггер: автоматически обновляет updated_at
CREATE FUNCTION set_updated_at() RETURNS trigger 
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END $$;

CREATE TRIGGER trg_tours_updated_at 
BEFORE UPDATE ON tours
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE tours_audit (
    id serial PRIMARY KEY,
    operation text NOT NULL,
    old_data jsonb,
    new_data jsonb,
    changed_by text,
    changed_at timestamptz DEFAULT clock_timestamp()
);

CREATE FUNCTION log_tour_changes() RETURNS trigger 
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO tours_audit (operation, new_data, changed_by)
        VALUES ('INSERT', to_jsonb(NEW), session_user);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO tours_audit (operation, old_data, new_data, changed_by)
        VALUES ('UPDATE', to_jsonb(OLD), to_jsonb(NEW), session_user);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO tours_audit (operation, old_data, changed_by)
        VALUES ('DELETE', to_jsonb(OLD), session_user);
    END IF;
    RETURN COALESCE(NEW, OLD);
END $$;

CREATE TRIGGER trg_tours_audit
AFTER INSERT OR UPDATE OR DELETE ON tours
FOR EACH ROW EXECUTE FUNCTION log_tour_changes();

-- Функция "Состояние на дату" (возвращает jsonb)
CREATE FUNCTION tour_state_at(p_tour_id integer, p_time timestamptz)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
    v_state jsonb;
BEGIN
    -- Берем последнее новое состояние до указанного времени (INSERT или UPDATE)
    SELECT new_data INTO v_state
    FROM tours_audit
    WHERE (new_data->>'id')::int = p_tour_id 
      AND changed_at <= p_time
      AND new_data IS NOT NULL
    ORDER BY changed_at DESC
    LIMIT 1;

    -- Если записи не было, значит тур был удален до этого времени
    IF v_state IS NULL THEN
        RETURN '{"status": "not_exists"}'::jsonb;
    END IF;

    RETURN v_state;
END;
$$;