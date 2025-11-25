CREATE TABLE IF NOT EXISTS `player_stats` (
    `identifier` VARCHAR(100) NOT NULL,
    `player_name` VARCHAR(255) NOT NULL,
    `discord_id` VARCHAR(50) DEFAULT NULL,
    `discord_avatar` TEXT DEFAULT NULL,
    `kills` INT(11) NOT NULL DEFAULT 0,
    `deaths` INT(11) NOT NULL DEFAULT 0,
    `assists` INT(11) NOT NULL DEFAULT 0,
    `headshots` INT(11) NOT NULL DEFAULT 0,
    `longest_kill_streak` INT(11) NOT NULL DEFAULT 0,
    `current_kill_streak` INT(11) NOT NULL DEFAULT 0,
    `last_updated` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`),
    INDEX `idx_kills` (`kills` DESC),
    INDEX `idx_discord` (`discord_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `kill_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `killer_identifier` VARCHAR(100) NOT NULL,
    `victim_identifier` VARCHAR(100) NOT NULL,
    `weapon` VARCHAR(100) DEFAULT NULL,
    `distance` FLOAT DEFAULT 0,
    `headshot` TINYINT(1) DEFAULT 0,
    `timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_killer` (`killer_identifier`),
    INDEX `idx_victim` (`victim_identifier`),
    INDEX `idx_timestamp` (`timestamp` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
