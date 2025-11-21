FROM debian:12

# Install NGINX
RUN apt-get update &&\
    apt-get upgrade -y &&\
    apt-get install -y nginx openssl

# Create SSL directory and generate self-signed certificate
RUN mkdir -p /etc/nginx/ssl &&\
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out /etc/nginx/ssl/cert.pem \
        -subj "/CN=fmixtur.42.fr"

COPY conf/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]