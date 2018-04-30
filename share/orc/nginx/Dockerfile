FROM openresty/openresty:alpine
ADD nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
ADD pow.lua /etc/nginx/pow.lua
RUN mkdir /pow

# Copy the SSL configuration into place
COPY ssl /etc/nginx/ssl
