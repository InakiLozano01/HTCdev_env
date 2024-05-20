FROM php:8.2-apache

# Copy php.ini before installing extensions
COPY config/php.ini /usr/local/etc/php/

# Install necessary libraries and tools
RUN apt-get update && apt-get install -y \
    openssh-server \
    libicu-dev \
    libpq-dev \
    libldap2-dev \
    libzip-dev \
    libxml2-dev \
    libmagickwand-dev \
    libcurl4-openssl-dev \
    git \
    libtool \
    pkg-config \
    libonig-dev \
    libeditreadline-dev \
    libedit-dev \
    openssl \
    libxslt-dev 

# Configurar LDAP antes de instalar las extensiones
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/

# Install PHP extensions
RUN docker-php-ext-install -j$(nproc) bcmath && echo "bcmath installed"
RUN docker-php-ext-install -j$(nproc) curl && echo "curl installed"
RUN docker-php-ext-install -j$(nproc) dom && echo "dom installed"
RUN docker-php-ext-install -j$(nproc) exif && echo "exif installed"
RUN docker-php-ext-install -j$(nproc) fileinfo && echo "fileinfo installed"
RUN docker-php-ext-install -j$(nproc) intl && echo "intl installed"
RUN docker-php-ext-install -j$(nproc) gd && echo "gd installed"
RUN docker-php-ext-install -j$(nproc) ldap && echo "ldap installed"
RUN docker-php-ext-install -j$(nproc) mbstring && echo "mbstring installed"
RUN docker-php-ext-install -j$(nproc) opcache && echo "opcache installed"
RUN docker-php-ext-install -j$(nproc) pcntl && echo "pcntl installed"
RUN docker-php-ext-install -j$(nproc) pdo && echo "pdo installed"
RUN docker-php-ext-install -j$(nproc) pdo_pgsql && echo "pdo_pgsql installed"
RUN docker-php-ext-install -j$(nproc) pgsql && echo "pgsql installed"
RUN docker-php-ext-install -j$(nproc) simplexml && echo "simplexml installed"
RUN docker-php-ext-install -j$(nproc) sockets && echo "sockets installed"
RUN docker-php-ext-install -j$(nproc) xml && echo "xml installed"
RUN docker-php-ext-install -j$(nproc) zip && echo "zip installed"
RUN docker-php-ext-install -j$(nproc) xsl && echo "xsl installed"

# Install and enable Xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Enable mod_rewrite for Apache
RUN a2enmod rewrite

# Install Composer
COPY --from=composer:2.7.6 /usr/bin/composer /usr/bin/composer

# Set the working directory
WORKDIR /var/www/html

# Configurar SSH y añadir usuarios
RUN mkdir /var/run/sshd \
    && echo 'root:password' | chpasswd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config \
    && useradd -m maxi && echo 'maxi:maxi123' | chpasswd \
    && useradd -m pedro && echo 'pedro:pedro123' | chpasswd \
    && useradd -m fernando && echo 'fernando:fernando123' | chpasswd \
    && useradd -m jpablo && echo 'jpablo:jpablo123' | chpasswd \
    && useradd -m jluis && echo 'jluis:jluis123' | chpasswd \
    && useradd -m facundo && echo 'facundo:facundo123' | chpasswd \
    && useradd -m inaki && echo 'inaki:inaki123' | chpasswd
    
# Expose SSH port
EXPOSE 2222

# Crear directorios de logs
RUN mkdir -p /var/log/apache2 \
    && touch /var/log/apache2/maxi_error.log \
    && touch /var/log/apache2/pedro_access.log \
    && touch /var/log/apache2/fernando_error.log \
    && touch /var/log/apache2/jpablo_access.log \
    && touch /var/log/apache2/jluis_error.log \
    && touch /var/log/apache2/facundo_access.log \
    && touch /var/log/apache2/inaki_error.log

# Configurar el nombre del servidor
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN chmod -R 755 /var/www/html
RUN chown -R www-data:www-data /var/www/html

# Crear un script de inicio para manejar múltiples servicios
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

COPY /config/maxi.conf /etc/apache2/sites-available/maxi.conf
COPY /config/pedro.conf /etc/apache2/sites-available/pedro.conf
COPY /config/fernando.conf /etc/apache2/sites-available/fernando.conf
COPY /config/jpablo.conf /etc/apache2/sites-available/jpablo.conf
COPY /config/jluis.conf /etc/apache2/sites-available/jluis.conf
COPY /config/facundo.conf /etc/apache2/sites-available/facundo.conf
COPY /config/inaki.conf /etc/apache2/sites-available/inaki.conf

RUN a2ensite maxi.conf
RUN a2ensite pedro.conf
RUN a2ensite fernando.conf
RUN a2ensite jpablo.conf
RUN a2ensite jluis.conf
RUN a2ensite facundo.conf
RUN a2ensite inaki.conf
RUN a2dissite 000-default.conf

# Iniciar Apache y SSH
CMD ["/usr/local/bin/start.sh"]
