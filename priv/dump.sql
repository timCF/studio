DROP DATABASE IF EXISTS `studio`;
CREATE DATABASE `studio`;
USE studio;
# rows NOT deletable !!!

#
#	SUPER ADMIN level
#

DROP TABLE IF EXISTS `admins`;
CREATE TABLE `admins` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL,
	`contacts` varchar(255) NOT NULL, # json {phones: [], mails: [], social: [], other: []}
	`login` varchar(255) NOT NULL,
	`password` varchar(255) NOT NULL,
	`enabled` int unsigned NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `name` (`name`),
	KEY `contacts` (`contacts`),
	KEY `login` (`login`),
	KEY `password` (`password`),
	KEY `enabled` (`enabled`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `locations`;
CREATE TABLE `locations` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL,
	`description` BLOB NOT NULL DEFAULT '',
	`enabled` int unsigned NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `name` (`name`),
	KEY `enabled` (`enabled`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `rooms`;
CREATE TABLE `rooms` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL,
	`location_id` bigint unsigned NOT NULL,
	`description` BLOB NOT NULL DEFAULT '',
	`price_base` bigint unsigned NOT NULL,
	`enabled` int unsigned NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `full` (`name`,`location_id`),
	KEY `price_base` (`price_base`),
	KEY `enabled` (`enabled`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `discount_const`;
CREATE TABLE `discount_const` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`room_id` bigint unsigned NOT NULL, # IF 0 - DEFAULT FOR ALL ROOMS ( !!!if room not exist here!!! )
	`band_kind` int unsigned NOT NULL, # 1 - base , 2 - cover , 3 - education # 0 - DEFAULT !!!
	`number_from` int unsigned NOT NULL, # number of sessions for 32 days ...
	`min_from` int unsigned NOT NULL, # min from day begin
	`week_day` int unsigned NOT NULL, # 1..7 # 0 - DEFAULT !!!
	`amount` bigint unsigned NOT NULL, # amount of discount in rub
	`fixprice` int unsigned NOT NULL, # if 1, cash is not applicative , get amount directly!!!
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `full` (`room_id`,`band_kind`,`number_from`,`min_from`,`week_day`),
	KEY `band_kind` (`band_kind`),
	KEY `number_from` (`number_from`),
	KEY `min_from` (`min_from`),
	KEY `week_day` (`week_day`),
	KEY `amount` (`amount`),
	KEY `fixprice` (`fixprice`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# TODO : discount_temp !!!



DROP TABLE IF EXISTS `instruments`;
CREATE TABLE `instruments` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL,
	`location_id` bigint unsigned NOT NULL,
	`description` BLOB NOT NULL DEFAULT '',
	`price` bigint unsigned NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `full` (`name`,`location_id`),
	KEY `price` (`price`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



#
#	ADMIN level
#



DROP TABLE IF EXISTS `bands`;
CREATE TABLE `bands` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL,
	`person` varchar(255) NOT NULL,
	`contacts` varchar(255) NOT NULL, # json {phones: [], mails: [], social: [], other: []}
	`kind` int unsigned NOT NULL, # 1 - base , 2 - cover , 3 - education
	`description` BLOB NOT NULL DEFAULT '',
	`balance` bigint NOT NULL,
	`admin_id` bigint unsigned NOT NULL,
	`can_order` int unsigned NOT NULL, # can order session in client app
	`enabled` int unsigned NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	KEY `name` (`name`),
	KEY `person` (`person`),
	KEY `contacts` (`contacts`),
	KEY `kind` (`kind`),
	KEY `balance` (`balance`),
	UNIQUE KEY `full` (`name`, `person`),
	KEY `admin_id` (`admin_id`),
	KEY `can_order` (`can_order`),
	KEY `enabled` (`enabled`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# rows NOT deletable
DROP TABLE IF EXISTS `sessions`;
CREATE TABLE `sessions` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`time_from` bigint unsigned NOT NULL,
	`time_to` bigint unsigned NOT NULL,
	`week_day` int unsigned NOT NULL, # 1..7
	`room_id` bigint unsigned NOT NULL,
	`instruments_ids` varchar(1024) NOT NULL, # json list [1,2,3 ... ]
	`band_id` bigint unsigned NOT NULL,
	`callback` int unsigned NOT NULL, # if not acceptable now, admin can call back later
	`status` int unsigned NOT NULL, # 0 - awaiting , 1 - awaiting first , 2 - denied from queue , 3 - canceled , 4 - hard canceled , 5 - done ok
	`price` bigint unsigned NOT NULL, # result price
	`description` BLOB NOT NULL DEFAULT '',
	`ordered_by` int unsigned NOT NULL, # 0 - program ( root ) , 1 - admin , 2 - self
	`admin_id_open` bigint unsigned NOT NULL,
	`admin_id_close` bigint unsigned NOT NULL,
	`transaction_id` bigint unsigned DEFAULT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	KEY `time_from` (`time_from`),
	KEY `time_to` (`time_to`),
	KEY `week_day` (`week_day`),
	KEY `room_id` (`room_id`),
	KEY `instruments_ids` (`instruments_ids`),
	KEY `band_id` (`band_id`),
	KEY `callback` (`callback`),
	KEY `status` (`status`),
	UNIQUE KEY `full` (`time_from`, `time_to`, `week_day`, `room_id`, `band_id`),
	KEY `price` (`price`),
	KEY `ordered_by` (`ordered_by`),
	KEY `admin_id_open` (`admin_id_open`),
	KEY `admin_id_close` (`admin_id_close`),
	KEY `transaction_id` (`transaction_id`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `sessions_template`;
CREATE TABLE `sessions_template` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`min_from` int unsigned NOT NULL, # min from day begin
	`min_to` int unsigned NOT NULL, # min from day begin
	`week_day` int unsigned NOT NULL, # 1..7
	`room_id` bigint unsigned NOT NULL,
	`instruments_ids` varchar(1024) NOT NULL, # json list [1,2,3 ... ]
	`band_id` bigint unsigned NOT NULL,
	`description` BLOB NOT NULL DEFAULT '',
	`admin_id` bigint unsigned NOT NULL,
	`enabled` int unsigned NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	KEY `min_from` (`min_from`),
	KEY `min_to` (`min_to`),
	KEY `week_day` (`week_day`),
	KEY `room_id` (`room_id`),
	KEY `instruments_ids` (`instruments_ids`),
	KEY `band_id` (`band_id`),
	UNIQUE KEY `full` (`min_from`, `min_to`, `week_day`, `room_id`, `band_id`),
	KEY `admin_id` (`admin_id`),
	KEY `enabled` (`enabled`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `transaction_id`;
CREATE TABLE `transaction_id` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`band_id` bigint unsigned NOT NULL,
	`kind` int unsigned NOT NULL, # 0 - payment , 1 - deposit , 2 - punishment
	`price` bigint unsigned NOT NULL, # - from balance
	`cash_in` bigint unsigned NOT NULL, # + to balance
	`cash_out` bigint unsigned NOT NULL, # - from balance
	`description` BLOB NOT NULL DEFAULT '',
	`admin_id` bigint unsigned NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	KEY `band_id` (`band_id`),
	KEY `kind` (`kind`),
	KEY `price` (`price`),
	KEY `cash_in` (`cash_in`),
	KEY `cash_out` (`cash_out`),
	KEY `admin_id` (`admin_id`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
