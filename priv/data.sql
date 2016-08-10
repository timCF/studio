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
( `name`, `location_id`, `color`, `price_base`, `enabled` )
VALUES
( 'metal', 1, '#d2a679', 1200, 1 ),
( 'rock', 1, '#66cc00', 1200, 1 ),
( 'jazz', 1, '#ff8000', 1200, 1 ),
( 'vip', 1, '#66ffff', 1200, 1 ),
( 'lux', 1, '#ffff00', 1200, 1 ),
( 'indie', 2, '#bc79d2', 1100, 1 );



INSERT INTO `discount_const`
( `room_id`, `band_kind`, `number_from`, `min_from`, `week_day`, `amount`, `fixprice` )
VALUES

#
#	DEFAULT
#

# base group

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

( 0, 'BK_cover', 0, 0, "WD_default", 600, 1 ),
( 0, 'BK_cover', 0, 1080, "WD_default", 0, 0 ),
( 0, 'BK_cover', 0, 1080, "WD_6", 0, 0 ),
( 0, 'BK_cover', 0, 1080, "WD_7", 0, 0 ),

( 0, 'BK_education', 0, 0, "WD_default", 450, 1 ),
( 0, 'BK_education', 0, 1080, "WD_default", 0, 0 ),
( 0, 'BK_education', 0, 1080, "WD_6", 0, 0 ),
( 0, 'BK_education', 0, 1080, "WD_7", 0, 0 ),

#
#	for other rooms
#

( 2, 'BK_base', 0, 0, "WD_default", 200, 0 ),
( 2, 'BK_base', 0, 1020, "WD_default", 0, 0 ),
( 2, 'BK_base', 4, 0, "WD_default", 300, 0 ),
( 2, 'BK_base', 4, 1020, "WD_default", 100, 0 ),
( 2, 'BK_base', 8, 0, "WD_default", 400, 0 ),
( 2, 'BK_base', 8, 1020, "WD_default", 200, 0 ),

( 2, 'BK_base', 0, 0, "WD_6", 0, 0 ),
( 2, 'BK_base', 4, 0, "WD_6", 100, 0 ),
( 2, 'BK_base', 8, 0, "WD_6", 200, 0 ),

( 2, 'BK_base', 0, 0, "WD_7", 0, 0 ),
( 2, 'BK_base', 4, 0, "WD_7", 100, 0 ),
( 2, 'BK_base', 8, 0, "WD_7", 200, 0 ),

( 2, 'BK_cover', 0, 0, "WD_default", 600, 1 ),
( 2, 'BK_cover', 0, 1020, "WD_default", 0, 0 ),
( 2, 'BK_cover', 0, 1020, "WD_6", 0, 0 ),
( 2, 'BK_cover', 0, 1020, "WD_7", 0, 0 ),

( 2, 'BK_education', 0, 0, "WD_default", 450, 1 ),
( 2, 'BK_education', 0, 1020, "WD_default", 0, 0 ),
( 2, 'BK_education', 0, 1020, "WD_6", 0, 0 ),
( 2, 'BK_education', 0, 1020, "WD_7", 0, 0 );



INSERT INTO `instruments`
( `name`, `location_id`, `price` , `enabled`)
VALUES
( 'Fender Stratocaster', 1, 100, 1),
( 'Schecter Bass', 1, 100, 1),
( 'Samick Anne Rose', 2, 100, 1);



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
