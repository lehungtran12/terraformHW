#!/bin/bash
apt update -y 
apt install nodejs npm -y
# apt install nginx -y
apt install docker.io -y
cd /home/ubuntu && git clone https://github.com/sweetiu172/Blog-React-CRUD-MYSQL.git
cd /home/ubuntu/Blog-React-CRUD-MYSQL/frontend
#yarn && yarn start
docker build -t frontend .
docker run -d -p 80:3000 frontend
# cat > /etc/nginx/sites-available/default <<EOF
# server {
#     listen 80;
#     location / {
#         proxy_pass http://localhost:3000;
#     }
# }
# EOF
# systemctl restart nginx
