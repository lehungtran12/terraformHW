#!/bin/bash
apt update -y 
apt install nodejs -y
apt install docker.io -y
cd /home/ubuntu && git clone https://github.com/sweetiu172/Blog-React-CRUD-MYSQL.git
cd /home/ubuntu/Blog-React-CRUD-MYSQL/frontend
docker build -t frontend .
docker run -d -p 80:3000 frontend
