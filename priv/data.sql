USE studio;

INSERT INTO `admins`
( `name`, `contacts`, `login`, `password`, `enabled` )
VALUES
( 'root', '{"phones":[],"mails":[],"social":[],"other":[]}', 'root', 'f9bb5c75-d7b3-4a6e-bc11-b419e3a45fdd', 1 );



INSERT INTO `locations`
( `name`, `enabled` )
VALUES
( 'lemooor-1', 1 ),
( 'lemooor-2', 1 );



INSERT INTO `rooms`
( `name`, `location_id`, `price_base`, `enabled` )
VALUES
( 'metal', 1, 1200, 1 ),
( 'indie', 2, 1100, 1 );



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
( `name`, `location_id`, `price` )
VALUES
( 'Fender Stratocaster', 1, 100 ),
( 'Schecter Bass', 1, 100 ),
( 'Samick Anne Rose', 2, 100 );



INSERT INTO `bands`
( `name`, `person`, `contacts`, `kind`, `balance`, `admin_id`, `can_order`, `enabled` )
VALUES
( 'Тэйсит Фьюри', 'Пельмень', '{"phones":[],"mails":[],"social":[],"other":[]}', 'BK_base', 1200, 1, 1, 1 );



#
#	TODO : template , test transactions
#
