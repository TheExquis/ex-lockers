
CREATE TABLE IF NOT EXISTS `tslockers` (
  `lockerid` int(20) NOT NULL AUTO_INCREMENT,
  `owner` varchar(255) NOT NULL,
  `password` int(11) DEFAULT 0,
  `branch` varchar(50) NOT NULL,
  KEY `lockerid` (`lockerid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
