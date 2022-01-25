CREATE DATABASE openemrdb;
CREATE USER 'openemr_user'@'localhost' IDENTIFIED BY 'PASSWORD';
GRANT ALL PRIVILEGES ON openemrdb.* TO 'openemr_user'@'localhost';
FLUSH PRIVILEGES;
