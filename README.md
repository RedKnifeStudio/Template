## [![RedKnife](https://redknife-studio.pl/web/image/website/1/logo/RedKnife%20Studio?unique=323bc66)](https://odoo.redknife-studio.pl/)
----
[![OdooDocs](http://img.shields.io/badge/master-docs-875A7B.svg?style=flat&colorA=8F8F8F)](https://www.odoo.com/documentation/master/)

## Moving on the Branches
----

 - Any modules must be first tested on Test Branch
 - Every change should be included in Changelog
 - After testing merge branch Test with Production with 
 


### Odoo Instalation
----

For an installation please follow the <a href="https://docs.google.com/document/d/10VVQVLrepNTJucuF8qVKm10-Sm9ChrJddxK4090fzfU/edit?usp=sharing" target="_blank">Setup instructions</a>
from the documentation.

### NGINX Instalation
----

1. Clone Repository to local VM. 
2. Open Scripts Directory.
3. Open **prod.conf** and **test.conf**
4. Change *url.com* to your *server url*
5. Send Scripts **Directory** to the server using **scp -r Scripts/ root@ipv4:~/**
6. Log in to the server
7. Follow to the Scripts directory 
8. Use script using **sudo ./nginx_ssl_odoo_v.2.2.0.sh**
9. Follow installation
