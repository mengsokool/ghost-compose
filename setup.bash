#!/bin/bash

# ตรวจสอบสิทธิ์ root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root" 
   exit 1
fi

# ฟังก์ชันตรวจสอบค่าอินพุต
function validate_input() {
    if [[ -z "$1" ]]; then
        echo "❌ Error: $2 cannot be empty!"
        exit 1
    fi
}

# ตรวจสอบและติดตั้ง Docker
if ! command -v docker &> /dev/null; then
    echo "🔹 Installing Docker..."
    sudo apt update && sudo apt install -y docker.io
fi

# ตรวจสอบว่าเป็น Docker Compose รุ่นเก่าหรือใหม่
DOCKER_COMPOSE_CMD="docker-compose"
if ! command -v $DOCKER_COMPOSE_CMD &> /dev/null; then
  # ถ้าไม่พบคำสั่ง docker-compose, ตรวจสอบเวอร์ชั่นใหม่
  DOCKER_COMPOSE_CMD="docker compose"
  if ! command -v $DOCKER_COMPOSE_CMD &> /dev/null; then
    # ถ้าไม่พบทั้งสองคำสั่ง
    echo "🔹 Installing Docker Compose..."
    sudo apt install -y docker-compose
  else
    DOCKER_COMPOSE_CMD="docker compose"
  fi
fi

# ให้ผู้ใช้ป้อนค่าที่จำเป็น (ไม่มีค่า default สำหรับ DOMAIN และ EMAIL)
echo "Enter your domain (e.g., example.com):"
read DOMAIN
validate_input "$DOMAIN" "Domain"

echo "Enter your email for SSL certificate notifications:"
read EMAIL
validate_input "$EMAIL" "Email"

# กำหนด default value สำหรับ MySQL root password และ Ghost database password
echo "Enter MySQL root password [default: rootpassword]:"
read -s MYSQL_ROOT_PASSWORD
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-rootpassword}
echo "Using MySQL root password."

echo "Enter Ghost database password [default: ghostpassword]:"
read -s GHOST_DB_PASSWORD
GHOST_DB_PASSWORD=${GHOST_DB_PASSWORD:-ghostpassword}
echo "Using Ghost database password."

# สร้างโฟลเดอร์โปรเจค
mkdir -p ghost-compose/nginx/conf.d ghost-compose/nginx/ssl ghost-compose/mysql/data ghost-compose/ghost/content
cd ghost-compose || exit

# สร้างไฟล์ docker-compose.yml
cat > docker-compose.yml <<EOL
version: '3.7'
services:
  ghost:
    image: ghost:latest
    restart: always
    depends_on:
      - db
    environment:
      NODE_ENV: production
      url: https://$DOMAIN
      database__client: mysql
      database__connection__host: db
      database__connection__user: ghost
      database__connection__password: $GHOST_DB_PASSWORD
      database__connection__database: ghostdb
    volumes:
      - ./ghost/content:/var/lib/ghost/content
  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
      MYSQL_USER: ghost
      MYSQL_PASSWORD: $GHOST_DB_PASSWORD
      MYSQL_DATABASE: ghostdb
    volumes:
      - ./mysql/data:/var/lib/mysql
  nginx:
    image: nginx:latest
    restart: always
    depends_on:
      - ghost
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/ssl:/etc/letsencrypt/live/$DOMAIN/
      - ./nginx/ssl-dhparams:/etc/ssl/certs/
    command: ["nginx", "-g", "daemon off;"]
  certbot:
    image: certbot/certbot
    volumes:
      - ./nginx/ssl:/etc/letsencrypt/
      - ./nginx/ssl-dhparams:/etc/ssl/certs/
      - ./nginx/conf.d:/var/www/certbot/
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do sleep 6h & wait $${!}; certbot renew; done;'"
networks:
  default:
    driver: bridge
EOL

# สร้างไฟล์ Nginx config
cat > nginx/conf.d/default.conf <<EOL
server {
    listen 80;
    server_name $DOMAIN;
    location / {
        root /var/www/certbot;
    }
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }
    location / {
        return 301 https://\$host\$request_uri;
    }
}
server {
    listen 443 ssl;
    server_name $DOMAIN;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    location / {
        proxy_pass http://ghost:2368;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
EOL

# สร้าง SSL Certificate
sudo $DOCKER_COMPOSE_CMD down
sudo certbot certonly --standalone --non-interactive --agree-tos -m $EMAIL -d $DOMAIN

# เรียกใช้งาน Docker Compose
sudo $DOCKER_COMPOSE_CMD up -d

echo "✅ Setup completed! Visit https://$DOMAIN to access your Ghost CMS."
