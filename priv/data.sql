USE studio;

INSERT INTO `admins`
( `name`, `contacts`, `login`, `password`, `enabled` )
VALUES
( 'root', '{"phones":[],"mails":[],"social":[],"other":[]}', 'root', 'f9bb5c75-d7b3-4a6e-bc11-b419e3a45fdd', 1 ),
( 'Саша Минаев', '{"phones":["89257904809"],"mails":[],"social":["https://vk.com/snowhitebeats"],"other":[]}', 'snowhitebeats', 'salmon', 1 );



INSERT INTO `locations`
( `name`, `enabled` )
VALUES
( 'lemooor-1', 1 ),
( 'lemooor-2', 1 );



INSERT INTO `rooms`
( `id`, `name`, `location_id`, `color`, `price_base`, `enabled` )
VALUES
# lemooor_1
( 1, 'metal', 1, '#d2a679', 1200, 1 ),
( 2, 'rock', 1, '#66cc00', 1200, 1 ),
( 3, 'jazz', 1, '#ff8000', 1200, 1 ),
( 4, 'vip', 1, '#66ffff', 1500, 1 ),
( 5, 'lux', 1, '#ffff00', 1500, 1 ),
# lemooor_2
( 6, 'vintage', 2, '#ff66cc', 1100, 1 ),
( 7, 'progressive', 2, '#00cc66', 1100, 1 ),
( 8, 'indie', 2, '#00ccff', 1100, 1 ),
( 9, 'hard_rock', 2, '#cc33ff', 1300, 1 ),
( 10, 'turbo_metal', 2, '#ff3300', 1300, 1 ),
( 11, 'metal', 2, '#ff9900', 1300, 1 ),
( 12, 'modern_rock', 2, '#0066ff', 1300, 1 );



INSERT INTO `discount_const`
( `room_id`, `band_kind`, `number_from`, `min_from`, `week_day`, `amount`, `fixprice` )
VALUES

#
#	DEFAULT
#

# base

( 0, 'BK_base', 0, 0, "WD_default", 200, 0 ),
( 0, 'BK_base', 0, 1080, "WD_default", 0, 0 ),
( 0, 'BK_base', 4, 0, "WD_default", 300, 0 ),
( 0, 'BK_base', 4, 1080, "WD_default", 100, 0 ),
( 0, 'BK_base', 8, 0, "WD_default", 400, 0 ),
( 0, 'BK_base', 8, 1080, "WD_default", 200, 0 ),

( 0, 'BK_base', 0, 0, "WD_6", 0, 0 ),
( 0, 'BK_base', 4, 0, "WD_6", 100, 0 ),
( 0, 'BK_base', 8, 0, "WD_6", 200, 0 ),

( 0, 'BK_base', 0, 0, "WD_7", 0, 0 ),
( 0, 'BK_base', 4, 0, "WD_7", 100, 0 ),
( 0, 'BK_base', 8, 0, "WD_7", 200, 0 ),

# cover

( 4, 'BK_cover', 0, 0, "WD_default", 800, 1 ),
( 4, 'BK_cover', 0, 1080, "WD_default", 0, 0 ),
( 4, 'BK_cover', 0, 0, "WD_6", 0, 0 ),
( 4, 'BK_cover', 0, 0, "WD_7", 0, 0 ),

( 5, 'BK_cover', 0, 0, "WD_default", 800, 1 ),
( 5, 'BK_cover', 0, 1080, "WD_default", 0, 0 ),
( 5, 'BK_cover', 0, 0, "WD_6", 0, 0 ),
( 5, 'BK_cover', 0, 0, "WD_7", 0, 0 ),

( 0, 'BK_cover', 0, 0, "WD_default", 600, 1 ),
( 0, 'BK_cover', 0, 1080, "WD_default", 0, 0 ),
( 0, 'BK_cover', 0, 0, "WD_6", 0, 0 ),
( 0, 'BK_cover', 0, 0, "WD_7", 0, 0 ),

# education

( 0, 'BK_education', 0, 0, "WD_default", 450, 1 ),

#
# indie
#

( 8, 'BK_base', 0, 0, "WD_default", 200, 0 ),
( 8, 'BK_base', 0, 1020, "WD_default", 0, 0 ),
( 8, 'BK_base', 4, 0, "WD_default", 300, 0 ),
( 8, 'BK_base', 4, 1020, "WD_default", 100, 0 ),
( 8, 'BK_base', 8, 0, "WD_default", 400, 0 ),
( 8, 'BK_base', 8, 1020, "WD_default", 200, 0 ),

( 8, 'BK_base', 0, 0, "WD_6", 0, 0 ),
( 8, 'BK_base', 4, 0, "WD_6", 100, 0 ),
( 8, 'BK_base', 8, 0, "WD_6", 200, 0 ),

( 8, 'BK_base', 0, 0, "WD_7", 0, 0 ),
( 8, 'BK_base', 4, 0, "WD_7", 100, 0 ),
( 8, 'BK_base', 8, 0, "WD_7", 200, 0 ),

( 8, 'BK_cover', 0, 0, "WD_default", 600, 1 ),
( 8, 'BK_cover', 0, 1020, "WD_default", 0, 0 ),
( 8, 'BK_cover', 0, 0, "WD_6", 0, 0 ),
( 8, 'BK_cover', 0, 0, "WD_7", 0, 0 ),

( 8, 'BK_education', 0, 0, "WD_default", 450, 1 );

INSERT INTO `instruments`
( `name`, `location_id`, `price` , `enabled`)
VALUES
# lemooor_1

( 'Кардан', 1, 100, 1),

( 'Железо-100 1', 1, 100, 1),
( 'Железо-100 2', 1, 100, 1),
( 'Железо-100 3', 1, 100, 1),
( 'Железо-100 4', 1, 100, 1),
( 'Железо-100 5', 1, 100, 1),

( 'Железо-150 1', 1, 150, 1),
( 'Железо-150 2', 1, 150, 1),
( 'Железо-150 3', 1, 150, 1),
( 'Железо-150 4', 1, 150, 1),
( 'Железо-150 5', 1, 150, 1),

( 'Железо-200 1', 1, 200, 1),
( 'Железо-200 2', 1, 200, 1),
( 'Железо-200 3', 1, 200, 1),
( 'Железо-200 4', 1, 200, 1),
( 'Железо-200 5', 1, 200, 1),

( 'Одиночная педаль 1', 1, 50, 1),
( 'Одиночная педаль 2', 1, 50, 1),
( 'Одиночная педаль 3', 1, 50, 1),
( 'Одиночная педаль 4', 1, 50, 1),
( 'Одиночная педаль 5', 1, 50, 1),

( 'Малый барабан 1', 1, 50, 1),
( 'Малый барабан 2', 1, 50, 1),
( 'Малый барабан 3', 1, 50, 1),
( 'Малый барабан 4', 1, 50, 1),
( 'Малый барабан 5', 1, 50, 1),

( 'Гитара Fender Stratocaster', 1, 100, 1),
( 'Бас Schecter', 1, 100, 1),

( 'Синтезатор Casio 1', 1, 100, 1),
( 'Синтезатор Casio 2', 1, 100, 1),

# lemooor_2

( 'Кардан Mapex', 2, 100, 1),
( 'Кардан Pearl', 2, 200, 1),

( 'Железо-100 1', 2, 100, 1),
( 'Железо-100 2', 2, 100, 1),
( 'Железо-100 3', 2, 100, 1),
( 'Железо-100 4', 2, 100, 1),
( 'Железо-100 5', 2, 100, 1),
( 'Железо-100 6', 2, 100, 1),
( 'Железо-100 7', 2, 100, 1),

( 'Железо-150 1', 2, 150, 1),
( 'Железо-150 2', 2, 150, 1),
( 'Железо-150 3', 2, 150, 1),
( 'Железо-150 4', 2, 150, 1),
( 'Железо-150 5', 2, 150, 1),
( 'Железо-150 6', 2, 150, 1),
( 'Железо-150 7', 2, 150, 1),

( 'Железо-200 1', 2, 200, 1),
( 'Железо-200 2', 2, 200, 1),
( 'Железо-200 3', 2, 200, 1),
( 'Железо-200 4', 2, 200, 1),
( 'Железо-200 5', 2, 200, 1),
( 'Железо-200 6', 2, 200, 1),
( 'Железо-200 7', 2, 200, 1),

( 'Одиночная педаль 1', 2, 50, 1),
( 'Одиночная педаль 2', 2, 50, 1),
( 'Одиночная педаль 3', 2, 50, 1),
( 'Одиночная педаль 4', 2, 50, 1),
( 'Одиночная педаль 5', 2, 50, 1),
( 'Одиночная педаль 6', 2, 50, 1),
( 'Одиночная педаль 7', 2, 50, 1),

( 'Малый барабан 1', 2, 50, 1),
( 'Малый барабан 2', 2, 50, 1),
( 'Малый барабан 3', 2, 50, 1),
( 'Малый барабан 4', 2, 50, 1),
( 'Малый барабан 5', 2, 50, 1),
( 'Малый барабан 6', 2, 50, 1),
( 'Малый барабан 7', 2, 50, 1),

( 'Гитара Fender Stratocaster', 2, 100, 1),
( 'Гитара Samick', 2, 100, 1),
( 'Бас Yamaha', 2, 100, 1),

( 'Синтезатор Casio 1', 2, 100, 1),
( 'Синтезатор Casio 2', 2, 100, 1);



INSERT INTO `stuff2sell`
( `name`, `location_id`, `description`, `quantity`, `price`, `enabled` )
VALUES
( 'крона 9v', 1, '', 20, 100, 1 );



INSERT INTO `transactions`
( `kind`, `subject_id`, `subject_quantity`, `amount`, `cash_in`, `cash_out`, `description`, `admin_id` )
VALUES
( 'TK_sell', 1, 2, 200, 1000, 800, '', 2 ),
( 'TK_band_room', 1, 1, 1400, 2000, 600, '', 2 );



INSERT INTO `bands`
( `name`, `person`, `contacts`, `kind`, `balance`, `admin_id`, `can_order`, `enabled` )
VALUES
( 'Тэйсит Фьюри', 'Пельмень', '{"phones":["89266293872"],"mails":[],"social":["https://vk.com/german_fury","https://vk.com/enoth"],"other":[]}', 'BK_base', 6000, 2, 1, 1 );



INSERT INTO `sessions`
(
	`time_from`,
	`time_to`,
	`week_day`,
	`room_id`,
	`instruments_ids`,
	`band_id`,
	`callback`,
	`status`,
	`amount`,
	`price`,
	`description`,
	`ordered_by`,
	`admin_id_open`,
	`admin_id_close`,
	`transaction_id`
)
VALUES
(
	'2016-08-02 18:00:00',
	'2016-08-02 21:00:00',
	'WD_7',
	1,
	'[1,2]',
	1,
	1,
	'SS_closed_ok',
	1400,
	1400,
	'',
	'SO_admin',
	2,
	2,
	2
),
(
	'2016-08-05 18:00:00',
	'2016-08-05 21:00:00',
	'WD_1',
	1,
	'[1,2]',
	1,
	1,
	'SS_awaiting_first',
	1400,
	1400,
	'',
	'SO_admin',
	2,
	2,
	2
);



INSERT INTO `sessions_template`
( `min_from`, `min_to`, `week_day`, `room_id`, `instruments_ids`, `band_id`, `description`, `admin_id`, `enabled` )
VALUES
( 1080, 1260, 'WD_3', 1, '[1,2]', 1, '', 2, 1 ),
( 1260, 1440, 'WD_7', 1, '[1,2]', 1, '', 2, 1 );
