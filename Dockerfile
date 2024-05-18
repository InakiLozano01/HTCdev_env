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
    libedit-dev

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
    && useradd -m user1 && echo 'user1:password1' | chpasswd \
    && useradd -m user2 && echo 'user2:password2' | chpasswd
    
# Expose SSH port
EXPOSE 2222

# Crear directorios de logs
RUN mkdir -p /var/log/apache2 \
    && touch /var/log/apache2/user1_error.log \
    && touch /var/log/apache2/user1_access.log

# Configurar el nombre del servidor
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN chmod -R 755 /var/www/html
RUN chown -R www-data:www-data /var/www/html

# Crear un script de inicio para manejar múltiples servicios
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Iniciar Apache y SSH
CMD ["/usr/local/bin/start.sh"]
