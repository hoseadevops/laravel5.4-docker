create database hosea_db DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
grant all on hosea_db.* to 'hosea_w'@'%' identified by 'hosea';
flush privileges;