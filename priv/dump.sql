DROP DATABASE IF EXISTS `studio`;
CREATE DATABASE `studio`;
USE studio;
# rows NOT deletable !!!



DROP TABLE IF EXISTS `admins`;
CREATE TABLE `admins` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL,
	`contacts` varchar(255) NOT NULL, # json {phones: [], mails: [], social: [], other: []}
	`password` varchar(255) NOT NULL,
	`enabled` int unsigned NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `name` (`name`),
	KEY `contacts` (`contacts`),
	KEY `password` (`password`),
	KEY `enabled` (`enabled`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO
	`admins`
	(
		`name`,
		`contacts`,
		`password`,
		`enabled`
	)
VALUES
	(
		'root',
		'{"phones":[],"mails":[],"social":[],"other":[]}',
		'f9bb5c75-d7b3-4a6e-bc11-b419e3a45fdd',
		1
	);



DROP TABLE IF EXISTS `locations`;
CREATE TABLE `locations` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL,
	`enabled` int unsigned NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `name` (`name`),
	KEY `enabled` (`enabled`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO
	`locations`
	(
		`name`,
		`enabled`
	)
VALUES
	(
		'lemooor-1',
		1
	);



DROP TABLE IF EXISTS `rooms`;
CREATE TABLE `rooms` (
	`id` bigint unsigned NOT NULL AUTO_INCREMENT,
	`name` varchar(255) NOT NULL,
	`location_id` bigint unsigned NOT NULL,
	`price_base` bigint unsigned NOT NULL,
	`price_education` bigint unsigned NOT NULL,
	`price_d1` bigint unsigned NOT NULL,
	`price_d2` bigint unsigned NOT NULL,
	`price_cover` bigint unsigned NOT NULL,
	`enabled` int unsigned NOT NULL,
	`stamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`),
	UNIQUE KEY `full` (`name`,`location_id`),
	KEY `enabled` (`enabled`),
	KEY `stamp` (`stamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO
	`rooms`
	(
		`name`,
		`location_id`,
		`price_base`,
		`price_education`,
		`price_d1`,
		`price_d2`,
		`price_cover`,
		`enabled`
	)
VALUES
	(
		'metal',
		1,
		1000,
		450,
		900,
		800,
		600,
		1
	);
