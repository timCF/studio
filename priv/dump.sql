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
	`enabled` boolean NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `login` (`login`),
	KEY `name` (`name`),
	KEY `contacts` (`contacts`),
	KEY `password` (`password`),
	KEY `enabled` (`enabled`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `locations`;
CREATE TABLE `locations` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL,
	`description` BLOB NOT NULL DEFAULT '',
	`enabled` boolean NOT NULL,
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
	`color` varchar(255) NOT NULL,
	`description` BLOB NOT NULL DEFAULT '',
	`price_base` bigint unsigned NOT NULL,
	`enabled` boolean NOT NULL,
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
	`room_id` bigint unsigned NOT NULL, # IF 0 - DEFAULT FOR ALL ROOMS ( !!! if room not exist in this tab !!! )
	`band_kind` ENUM('BK_base','BK_cover','BK_education') NOT NULL,
	`number_from` int unsigned NOT NULL, # number of sessions for 32 days >= 0
	`min_from` int unsigned NOT NULL, # minutes from day begin
	`week_day` ENUM('WD_default','WD_1','WD_2','WD_3','WD_4','WD_5','WD_6','WD_7') NOT NULL,
	`amount` bigint unsigned NOT NULL, # amount of discount in rub
	`fixprice` boolean NOT NULL, # if 1, cash is not applicative discount , get amount directly !!!
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
	`enabled` boolean NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `full` (`name`,`location_id`),
	KEY `price` (`price`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



#
#	SUPER ADMIN + ADMIN
#



DROP TABLE IF EXISTS `stuff2sell`;
CREATE TABLE `stuff2sell` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL,
	`location_id` bigint unsigned NOT NULL,
	`description` BLOB NOT NULL DEFAULT '',
	`quantity` bigint unsigned NOT NULL,
	`price` bigint unsigned NOT NULL,
	`enabled` boolean NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `full` (`name`,`location_id`),
	KEY `quantity` (`quantity`),
	KEY `price` (`price`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `transactions`;
CREATE TABLE `transactions` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`kind` ENUM('TK_band_room','TK_band_instrument','TK_band_deposit','TK_band_punishment','TK_wage_base','TK_wage_bonus','TK_wage_punishment','TK_rent','TK_buy','TK_repair','TK_sell','TK_bonus') NOT NULL, # WITHOUT DEFAULT VALUE
	`subject_id` bigint unsigned NOT NULL, # band , admin or other stuff id
	`subject_quantity` bigint unsigned NOT NULL,
	`amount` bigint NOT NULL, # cash_in - cash_out
	`cash_in` bigint unsigned NOT NULL, # + to balance ( if band )
	`cash_out` bigint unsigned NOT NULL, # - from balance ( if band )
	`description` BLOB NOT NULL DEFAULT '',
	`admin_id` bigint unsigned NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`location_id` bigint unsigned NOT NULL,
	PRIMARY KEY (`id`),
	KEY `kind` (`kind`),
	KEY `subject_id` (`subject_id`),
	KEY `subject_quantity` (`subject_quantity`),
	KEY `amount` (`amount`),
	KEY `cash_in` (`cash_in`),
	KEY `cash_out` (`cash_out`),
	KEY `admin_id` (`admin_id`),
	KEY `stamp` (`stamp`),
	KEY `location_id` (`location_id`)
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
	`kind` ENUM('BK_base','BK_cover','BK_education') NOT NULL, # WITHOUT DEFAULT VALUE
	`description` BLOB NOT NULL DEFAULT '',
	`balance` bigint NOT NULL,
	`admin_id` bigint unsigned NOT NULL,
	`can_order` boolean NOT NULL, # can order session in client app
	`enabled` boolean NOT NULL,
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
	`time_from` timestamp NOT NULL DEFAULT '2016-07-14 17:10:04',
	`time_to` timestamp NOT NULL DEFAULT '2016-07-14 17:10:04',
	`week_day` ENUM('WD_1','WD_2','WD_3','WD_4','WD_5','WD_6','WD_7') NOT NULL, # WITHOUT DEFAULT VALUE
	`room_id` bigint unsigned NOT NULL,
	`instruments_ids` varchar(1024) NOT NULL, # json list [1,2,3 ... ]
	`band_id` bigint unsigned NOT NULL,
	`callback` boolean NOT NULL, # if not acceptable now for order, admin can call back later
	`status` ENUM('SS_awaiting_last','SS_awaiting_first','SS_closed_auto','SS_closed_ok','SS_canceled_soft','SS_canceled_hard') NOT NULL,
	`amount` bigint unsigned NOT NULL, # cash in
	`price` bigint unsigned NOT NULL,
	`description` BLOB NOT NULL DEFAULT '',
	`ordered_by` ENUM('SO_auto','SO_admin','SO_self') NOT NULL,
	`admin_id_open` bigint unsigned NOT NULL,
	`admin_id_close` bigint unsigned NOT NULL, # 0 if not closed yet
	`transaction_id` bigint unsigned DEFAULT NULL, # 0 if not closed yet
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
	UNIQUE KEY `full` (`time_from`, `time_to`, `week_day`, `room_id`, `band_id`, `status`),
	KEY `amount` (`amount`),
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
	`week_day` ENUM('WD_1','WD_2','WD_3','WD_4','WD_5','WD_6','WD_7') NOT NULL, # WITHOUT DEFAULT VALUE
	`room_id` bigint unsigned NOT NULL,
	`instruments_ids` varchar(1024) NOT NULL, # json list [1,2,3 ... ]
	`band_id` bigint unsigned NOT NULL,
	`description` BLOB NOT NULL DEFAULT '',
	`admin_id` bigint unsigned NOT NULL,
	`enabled` boolean NOT NULL,
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

ALTER TABLE `sessions_template` ADD `active_from` timestamp NOT NULL;
ALTER TABLE `sessions_template` ADD INDEX `active_from` (`active_from`);

ALTER TABLE `sessions` ADD `created_at` timestamp NOT NULL;
ALTER TABLE `sessions` ADD INDEX `created_at` (`created_at`);
