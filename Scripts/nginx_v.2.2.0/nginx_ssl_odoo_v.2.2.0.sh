#!/bin/bash
################################################################################
# Skrypt instalacyjny i konfiguracyjny NGINX wraz z certyfikatem SSL dla 2 subdomen        
# Wykorzystuje darmowy certyfikat SSL od Let's Encrypt
# Wersja 2.x.x wymaga załączników z ustawieniami konfiguracyjnymi do poszczególnych środowisk oraz edycji crona
# ------------------------------------------------------------------------------
# 0. Edytuj plik prod.conf oraz test.conf
# 1. Przerzuć cały folder na serwer przy użyciu polecenia sudo scp -r nazwa_folderu root@192.168.1.69:~/
# 2. Przekieruj rekord A domeny/subdomeny na adres IP serwera 
# 3. Dodaj uprawnienia poleceniem sudo chmod +x ./nginx_ssl_odoo_v.2.2.0.sh
# 4. Uruchom skrypt sudo ./nginx_ssl_odoo_v.2.2.0.sh
# ------------------------------------------------------------------------------
#
# ChangeLog
# v. 2.2.0 [27.10.2020] [Odoo 14 & Ubuntu 20.04]
# - poprawki w dokumentacji
# - dodanie reguły www -> non www
# - usunięcie linii ssl on;
# - wywołanie wczytania snippets lets encrypt przy redirect http -> https
# - edycja snippets ssl z 20m na 10m: ssl_session_cache shared:SSL:10m;
# - edycja snippets ssl z  add_header Strict-Transport-Security "max-age=15768000; includeSubdomains; preload";
#                       na add_header Strict-Transport-Security "max-age=15768000; includeSubDomains" always;
# - edycja snippets ssl usunięcie ssl_ecdh_curve secp384r1;
# - dodano instrukcję warunkową dla certyfikacji domeny z przedsrostkiem www
# 
# v. 2.1.6 [26.11.2019]
# - poprawki w dokumentacji
# - zmiana struktury plików i folderów
#
# v. 2.1.5 [27.08.2019]
# - dodano nagłówek "add_header Content-Security-Policy "upgrade-insecure-requests" always;" tym samym
#   eliminując problem z przejściem w tryb deweloperski z zasobami. Błąd spowodowany niezabezpieczonym URLem (HTTP)
# - poprawki w dokumentacji
#
# v. 2.1.0 [20.08.2019]
# - drobne poprawki automatycznego zatwierdzania aktualizacji systemowych
# - poprawki estetyczne
# - zmiana portu dla odoo-chat-test na 8172
# - zmiana nazwy i przeznaczenia skryptu (stricte dla Odoo)
# - zmiany w złącznikach
# - ogólne poprawki i optymalizacja w konfiguracji
#
# v. 2.0.4.3 [30.07.2019]
# - aktualizacja ustawień Let's Encrypta
# - zmiana portu (8572) i dodanie upstreamu dla odoo-chat-test (usunięcie problemu wygasającej sesji)
# - usunięcie automatycznej certyfikacji dla domen z przedrostkiem WWW
# - zmiana nazw plików konfiguracyjnych
#
# v. 2.0.3.7 [12.07.2019]
# - poprawka w załączniku konfiguracyjnym środowiska testowego
# - dodanie manualnego wprowadzania nazw środowisk
# - optymalizacja kodu
# - dodanie automatycznego odnawiania certyfikatu
#
# v. 2.0.1.2 [08.07.2019]
# - ujednolicenie pliku
# - zmiany konfiguracji w załącznikach, usuwające problem z JavaScriptem, podczas przechodzenia w tryb Developerski (z zasobami)
#
# Created by Dawid "Knifcio" Nowaliński
################################################################################
SCRIPT_NAME="NGINX && LET'S ENCRYPT (SSL) INSTALATION FOR ODOO ERP"
SCRIPT_VERSION="2.2.0"
WWW=""
ENV_P=""
ENV_T=""
LOCATION_SSL="/etc/nginx/snippets/ssl.conf"
LOCATION_LE="/etc/nginx/snippets/letsencrypt.conf"
SNIPPETS_SSL='
ssl_dhparam /etc/ssl/certs/dhparam.pem;\r
\r
ssl_session_timeout 1d;\r
ssl_session_cache shared:SSL:10m;\r
ssl_session_tickets off;\r
\r
ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;\r
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;\r
ssl_prefer_server_ciphers on;\r
\r
ssl_stapling on;\r
ssl_stapling_verify on;\r
resolver 8.8.8.8 8.8.4.4 valid=300s;\r
resolver_timeout 30s;\r
\r
add_header Strict-Transport-Security "max-age=15768000; includeSubdomains" always;\r
add_header X-Frame-Options SAMEORIGIN;\r
add_header X-Content-Type-Options nosniff;\r
add_header X-XSS-Protection "1; mode=block";\r
add_header Content-Security-Policy "upgrade-insecure-requests" always;\r
'
SNIPPETS_LE='
location ^~ /.well-known/acme-challenge/ {\r
\t  allow all;\r
\t  root /var/lib/letsencrypt/;\r
\t  default_type "text/plain";\r
\t  try_files $uri =404;\r
}
'

#---------------------------------------------------------------------------------------
#                                     Run installation script
#---------------------------------------------------------------------------------------
echo "=============================================================================="
echo "             Run script ${SCRIPT_NAME}  "
echo "                              ver.${SCRIPT_VERSION} "
echo "                       at $(date +"%Y.%m.%d %H:%M:%S") "
echo "=============================================================================="
echo "Enter your contact email for the installation of the certobot:"
read EMAIL_ADDRESS
echo "Enter your domain: (without www. eg. odoo.com)"
read DOMAIN_NAME
echo "You are going to additionally certify the domain with the prefix www? (Y/N)"
read WWW
echo "Enter your production environment: (eg. odoo. or blank)"
read ENV_P
echo "Enter your test environment: (eg. test.)"
read ENV_T


#---------------------------------------------------------------------------------------
#                                      Install NGINX
#---------------------------------------------------------------------------------------
echo "**************************************************************************"
echo ">	                             Update Server "
echo "**************************************************************************"
sudo apt update -y
sudo apt-get update -y
sudo apt upgrade -y
sudo apt-get upgrade -y

echo "**************************************************************************"
echo ">	                             Install NGINX "
echo "**************************************************************************"
echo "Install NGINX"
sudo apt install nginx -y

echo "Configure Firewall settings"
sudo ufw allow 'Nginx Full'

echo "Restart the NGINX service"
sudo systemctl restart nginx

#---------------------------------------------------------------------------------------
#                                     Install Let's Encrypt
#---------------------------------------------------------------------------------------
echo "**************************************************************************"
echo ">	                             Update Server "
echo "**************************************************************************"
sudo apt update -y
sudo apt upgrade -y

echo "**************************************************************************"
echo ">	                     Downloading the repository Let's Encrypt "
echo "**************************************************************************"
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt update -y

echo "**************************************************************************"
echo ">	                   Installing certbot and generating SSL keys "
echo "**************************************************************************"
sudo apt install certbot -y

echo "Generating a 2048-bit SSL key"
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

sudo mkdir -p /var/lib/letsencrypt/.well-known
sudo chgrp www-data /var/lib/letsencrypt
sudo chmod g+s /var/lib/letsencrypt


#---------------------------------------------------------------------------------------
#                         Installation and configuration of certificates
#---------------------------------------------------------------------------------------
echo "**************************************************************************"
echo ">	                   Configuring Snippets  "
echo "**************************************************************************"
echo "Creating an SSL configuration"
echo -e $SNIPPETS_SSL > ${LOCATION_SSL}
sudo chmod 666 ${LOCATION_SSL}

echo -e $SNIPPETS_LE > ${LOCATION_LE}
sudo chmod 666 ${LOCATION_LE}

echo "**************************************************************************"
echo ">	        Configuration of the production instance for certification "
echo "**************************************************************************"
echo "Deleting the default NGINX settings"
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default

LOCATION_NGINX="/etc/nginx/sites-available/$ENV_P$DOMAIN_NAME.conf"
NGINX_CERT_CONF="server {\r
\t  listen 80;\r
\t  server_name $ENV_P$DOMAIN_NAME www.$ENV_P$DOMAIN_NAME;\r
\r
\t  include snippets/letsencrypt.conf;\r
}"

echo "Basic NGINX configuration for SSL certification of the production subdomain"
echo -e $NGINX_CERT_CONF > ${LOCATION_NGINX}
sudo chmod 666 ${LOCATION_NGINX}

sudo ln -s /etc/nginx/sites-available/$ENV_P$DOMAIN_NAME.conf /etc/nginx/sites-enabled/$ENV_P$DOMAIN_NAME.conf
sudo systemctl restart nginx

echo "**************************************************************************"
echo ">	           SSL certification of the production environment "
echo "**************************************************************************"
if [ $WWW == "Y" ];then
    sudo certbot certonly --agree-tos --email $EMAIL_ADDRESS --webroot -w /var/lib/letsencrypt/ -d $ENV_P$DOMAIN_NAME -d www.$ENV_P$DOMAIN_NAME -n
 else
    sudo certbot certonly --agree-tos --email $EMAIL_ADDRESS --webroot -w /var/lib/letsencrypt/ -d $ENV_P$DOMAIN_NAME -n
fi

echo "**************************************************************************"
echo ">	           Configuration of the test instance for certification "
echo "**************************************************************************"
echo "Removing the basic NGINX configuration of the production subdomain"
sudo rm /etc/nginx/sites-available/$ENV_P$DOMAIN_NAME.conf
sudo rm /etc/nginx/sites-enabled/$ENV_P$DOMAIN_NAME.conf

LOCATION_NGINX="/etc/nginx/sites-available/$ENV_T$DOMAIN_NAME.conf"
NGINX_CERT_CONF="server {\r
\t  listen 80;\r
\t  server_name $ENV_T$DOMAIN_NAME www.$ENV_T$DOMAIN_NAME;\r
\r
\t  include snippets/letsencrypt.conf;\r
}"

echo "Basic NGINX configuration for SSL certification of the test subdomain"
echo -e $NGINX_CERT_CONF > ${LOCATION_NGINX}
sudo chmod 666 ${LOCATION_NGINX}
sudo ln -s /etc/nginx/sites-available/$ENV_T$DOMAIN_NAME.conf /etc/nginx/sites-enabled/$ENV_T$DOMAIN_NAME.conf
sudo systemctl restart nginx

echo "**************************************************************************"
echo ">	           SSL certification of the test environment "
echo "**************************************************************************"
if [ $WWW == "Y" ];then
    sudo certbot certonly --agree-tos --email $EMAIL_ADDRESS --webroot -w /var/lib/letsencrypt/ -d $ENV_T$DOMAIN_NAME -d www.$ENV_T$DOMAIN_NAME -n
 else
    sudo certbot certonly --agree-tos --email $EMAIL_ADDRESS --webroot -w /var/lib/letsencrypt/ -d $ENV_T$DOMAIN_NAME -n
fi


#---------------------------------------------------------------------------------------
#                                     The final NGINX configuration
#---------------------------------------------------------------------------------------
echo "**************************************************************************"
echo ">	           NGINX configuration for a production and test instance "
echo "**************************************************************************"
echo "Removing the basic NGINX configuration of the test subdomain"
sudo rm /etc/nginx/sites-available/$ENV_T$DOMAIN_NAME.conf
sudo rm /etc/nginx/sites-enabled/$ENV_T$DOMAIN_NAME.conf

mv ./test.conf /etc/nginx/sites-available/$ENV_T$DOMAIN_NAME.conf
sudo ln -s /etc/nginx/sites-available/$ENV_T$DOMAIN_NAME.conf /etc/nginx/sites-enabled/$ENV_T$DOMAIN_NAME.conf

mv ./prod.conf /etc/nginx/sites-available/$ENV_P$DOMAIN_NAME.conf
sudo ln -s /etc/nginx/sites-available/$ENV_P$DOMAIN_NAME.conf /etc/nginx/sites-enabled/$ENV_P$DOMAIN_NAME.conf

sudo nginx -t
sudo systemctl restart nginx

echo "Starting the automatic certificate update"
sudo rm /etc/cron.d/certbot
mv ./certbot /etc/cron.d/certbot
sudo certbot renew --dry-run

echo "Restart NGINX, Odoo production and test environment"
sudo systemctl restart nginx
sudo systemctl restart odooprod-server.service
sudo systemctl restart odootest-server.service
echo "**************************************************************************"
echo "Instalation was finished on $(date +"%Y.%m.%d %H:%M:%S")" 
echo "**************************************************************************"
