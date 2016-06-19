USE studio;

INSERT INTO `admins`
( `name`, `contacts`, `login`, `password`, `enabled` )
VALUES
( 'root', '{"phones":[],"mails":[],"social":[],"other":[]}', 'root', 'f9bb5c75-d7b3-4a6e-bc11-b419e3a45fdd', 1 );



INSERT INTO `locations`
( `name`, `enabled` )
VALUES
( 'lemooor-1', 1 ),
( 'lemooor-2', 2 );



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

( 0, 1, 0, 0, 0, 200, 0 ),
( 0, 1, 0, 1080, 0, 0, 0 ),
( 0, 1, 4, 0, 0, 300, 0 ),
( 0, 1, 4, 1080, 0, 100, 0 ),
( 0, 1, 8, 0, 0, 400, 0 ),
( 0, 1, 8, 1080, 0, 200, 0 ),

( 0, 1, 0, 0, 6, 0, 0 ),
( 0, 1, 4, 0, 6, 100, 0 ),
( 0, 1, 8, 0, 6, 200, 0 ),

( 0, 1, 0, 0, 7, 0, 0 ),
( 0, 1, 4, 0, 7, 100, 0 ),
( 0, 1, 8, 0, 7, 200, 0 ),

# cover

( 0, 2, 0, 0, 0, 600, 1 ),
( 0, 2, 0, 1080, 0, 0, 0 ),
( 0, 2, 0, 1080, 6, 0, 0 ),
( 0, 2, 0, 1080, 7, 0, 0 ),

# education

( 0, 3, 0, 0, 0, 450, 1 ),
( 0, 3, 0, 1080, 0, 0, 0 ),
( 0, 3, 0, 1080, 6, 0, 0 ),
( 0, 3, 0, 1080, 7, 0, 0 ),

#
#	for other rooms
#

# base group

( 2, 1, 0, 0, 0, 200, 0 ),
( 2, 1, 0, 1020, 0, 0, 0 ),
( 2, 1, 4, 0, 0, 300, 0 ),
( 2, 1, 4, 1020, 0, 100, 0 ),
( 2, 1, 8, 0, 0, 400, 0 ),
( 2, 1, 8, 1020, 0, 200, 0 ),

( 2, 1, 0, 0, 6, 0, 0 ),
( 2, 1, 4, 0, 6, 100, 0 ),
( 2, 1, 8, 0, 6, 200, 0 ),

( 2, 1, 0, 0, 7, 0, 0 ),
( 2, 1, 4, 0, 7, 100, 0 ),
( 2, 1, 8, 0, 7, 200, 0 ),

# cover

( 2, 2, 0, 0, 0, 600, 1 ),
( 2, 2, 0, 1020, 0, 0, 0 ),
( 2, 2, 0, 1020, 6, 0, 0 ),
( 2, 2, 0, 1020, 7, 0, 0 ),

# education

( 2, 3, 0, 0, 0, 450, 1 ),
( 2, 3, 0, 1020, 0, 0, 0 ),
( 2, 3, 0, 1020, 6, 0, 0 ),
( 2, 3, 0, 1020, 7, 0, 0 );



INSERT INTO `instruments`
( `name`, `location_id`, `price` )
VALUES
( 'Fender Stratocaster', 1, 100 ),
( 'Schecter Bass', 1, 100 ),
( 'Samick Anne Rose', 2, 100 );



INSERT INTO `bands`
( `name`, `person`, `contacts`, `kind`, `balance`, `admin_id`, `can_order`, `enabled` )
VALUES
( 'Тэйсит Фьюри', 'Пельмень', '{"phones":[],"mails":[],"social":[],"other":[]}', 1, 1200, 1, 1, 1 );



#
#	TODO : template , test transactions
#
