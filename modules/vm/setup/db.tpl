#!/bin/bash
set -e

# Update system packages
sudo dnf -y update

# Install OpenSSH server
sudo dnf install -y openssh-server
sudo systemctl enable sshd
sudo systemctl start sshd

# Install PostgreSQL 17 server (17.6 currently)
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql17-server postgresql17

# Initialize and enable PostgreSQL service
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb
sudo systemctl enable postgresql-17
sudo systemctl start postgresql-17

# Backup originals
sudo cp /var/lib/pgsql/17/data/pg_hba.conf /var/lib/pgsql/17/data/pg_hba.conf.bak
sudo cp /var/lib/pgsql/17/data/postgresql.conf /var/lib/pgsql/17/data/postgresql.conf.bak

# Listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/17/data/postgresql.conf

# Allow password-based connections from local network
sudo echo "host all all ${address_space} md5" >> /var/lib/pgsql/17/data/pg_hba.conf

# Restart PostgreSQL to apply config
sudo systemctl restart postgresql-17

# Init database and create user
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${db_admin_password}';"
sudo -u postgres psql <<EOF
CREATE DATABASE scdf;
DROP SCHEMA public CASCADE;
CREATE USER scdf_usr WITH PASSWORD '${db_usr_password}';
GRANT ALL PRIVILEGES ON DATABASE scdf TO scdf_usr;
\c scdf;
EOF