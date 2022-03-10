CREATE TABLE `tslockers` (
	`dbid` INT(20) NOT NULL AUTO_INCREMENT,
	`lockerid` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_general_ci',
	`owner` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_general_ci',
	`password` VARCHAR(20) NOT NULL DEFAULT '123' COLLATE 'utf8mb4_general_ci',
	`branch` VARCHAR(20) NOT NULL COLLATE 'utf8mb4_general_ci',
	PRIMARY KEY (`dbid`) USING BTREE,
	INDEX `lockerid` (`lockerid`) USING BTREE
)
COLLATE='utf8mb4_general_ci'
ENGINE=InnoDB
;
