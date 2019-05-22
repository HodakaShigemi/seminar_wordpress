#!/bin/bash -xv

# 以下のDB_HOST, DB_USER, DB_PASSWORD の値をRDSの情報に変更してあげる
DB_HOST=seminar-db.cx3qqr5ityu0.us-east-1.rds.amazonaws.com
DB_USER=seminar
DB_PASSWORD=seminarpassword

# WordPress configs
WP_ACCESS_RANGE=10.0.0.0/255.255.0.0

# MySQL user wordpress password
WP_PASSWORD=CXQwJxMXT4sB


yum update -y
yum install -y httpd mariadb
amazon-linux-extras install php7.2
yum install -y php-mysqlnd

cat << DDL > /opt/wordpress.ddl
CREATE DATABASE wordpress;
GRANT ALL PRIVILEGES ON wordpress.* TO "wordpressuser"@"${WP_ACCESS_RANGE}" IDENTIFIED BY "${WP_PASSWORD}";
FLUSH PRIVILEGES;
EXIT
DDL

mysql -h ${DB_HOST} -u ${DB_USER} --password=${DB_PASSWORD} < /opt/wordpress.ddl

curl https://wordpress.org/latest.tar.gz | tar -zx
mv wordpress /var/www/


function random_string(){
  head -c $(( $1 * 3/2 )) /dev/urandom | \
  base64 | \
  head -c $1
}

cat <<EOL > /var/www/wordpress/wp-config.php
<?php
// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** MySQL database username */
define( 'DB_USER', 'wordpressuser' );

/** MySQL database password */
define( 'DB_PASSWORD', '${WP_PASSWORD}' );

/** MySQL hostname */
define( 'DB_HOST', '${DB_HOST}' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         '$(random_string 64)' );
define( 'SECURE_AUTH_KEY',  '$(random_string 64)' );
define( 'LOGGED_IN_KEY',    '$(random_string 64)' );
define( 'NONCE_KEY',        '$(random_string 64)' );
define( 'AUTH_SALT',        '$(random_string 64)' );
define( 'SECURE_AUTH_SALT', '$(random_string 64)' );
define( 'LOGGED_IN_SALT',   '$(random_string 64)' );
define( 'NONCE_SALT',       '$(random_string 64)' );

EOL

cat <<'EOL' >> /var/www/wordpress/wp-config.php
/**
 * WordPress Database Table prefix.
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 */
define( 'WP_DEBUG', false );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );
EOL

chown -R apache:apache /var/www/wordpress

sed --in-place  's%^DocumentRoot "/var/www/html"%DocumentRoot "/var/www/wordpress"%' /etc/httpd/conf/httpd.conf
sed --in-place  's%^<Directory "/var/www">%<Directory "/var/www/wordpress">%' /etc/httpd/conf/httpd.conf
sed --in-place -r '/^<Directory "\/var\/www\/wordpress">/,/^<\/Directory>/ s/.*AllowOverride None/    AllowOverride All/' /etc/httpd/conf/httpd.conf

systemctl daemon-reload

systemctl start httpd
systemctl enable httpd

