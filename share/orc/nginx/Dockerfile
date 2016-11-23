# We're going to use a really small image, since we're not compiling anything
# in this image
FROM nginx:alpine

# Replace the standard nginx.conf with our custom version
COPY nginx.conf /etc/nginx/nginx.conf

# Copy the SSL configuration into place
COPY ssl /etc/nginx/ssl
