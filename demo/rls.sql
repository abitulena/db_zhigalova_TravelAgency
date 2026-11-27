-- [step] Под клиентом 1 видим только его строки
SET ROLE app_client;
SET app.client_id = '1';
SELECT count(*) FROM bookings;
-- expect: value 1
RESET ROLE;

-- [step] Под клиентом 2 видим только его строки
SET ROLE app_client;
SET app.client_id = '2';
SELECT count(*) FROM bookings;
-- expect: value 1
RESET ROLE;

-- [step] Суперпользователь видит все строки (политика не действует)
SELECT count(*) FROM bookings;
-- expect: value 2009