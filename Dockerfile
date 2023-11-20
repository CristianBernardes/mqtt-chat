# Use a imagem baseada em Alpine com PHP 8.2 FPM
FROM php:8.2-fpm-alpine

# Arguments
ARG user=chat
ARG uid=1000

# Atualize os pacotes do sistema operacional
RUN apk update && apk upgrade

# Instale os pacotes necessários
RUN apk add --no-cache \
    nodejs \
    npm \
    libzip-dev \
    zip \
    unzip \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    g++ \
    lame && \
    rm -rf /var/cache/apk/*

# Instale as extensões PHP necessárias
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) gd && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-install intl && \
    docker-php-ext-install zip

# Instale o Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#/usr/local/etc/php/conf.
RUN adduser --uid $uid --home /home/$user -s /bin/sh -D $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Crie o diretório de trabalho
WORKDIR /var/www/html

# Copie o código fonte do Laravel para o diretório de trabalho
COPY . .

# Defina as permissões para o diretório de trabalho
RUN chown -R www-data:www-data /var/www/html

# Defina o usuário com o qual o contêiner será executado
USER $user

# Inicia o Laravel
# Este ENTRYPOINT verifica se o arquivo "composer.lock" e o diretório "vendor" existem.
# Se ambos existirem, ele inicia o servidor Laravel.
# Caso contrário, ele executa "composer install" para instalar as dependências ausentes
# e, em seguida, inicia o servidor.
ENTRYPOINT if [ -f "composer.lock" ] && [ -d "vendor" ]; then php artisan serve --host=0.0.0.0 --port=8009; else composer install --ignore-platform-reqs && npm install && npm run build && php artisan serve --host=0.0.0.0 --port=8009; fi

# Expõe a porta 8009
EXPOSE 8009
