#!/bin/bash

# Скрипт автоматического развёртывания проекта на Yandex Cloud VM

# Переменные
REPO_URL="https://github.com/songspeta/shvirtd-example-python-netology-hw.git"
PROJECT_DIR="/opt/shvirtd-example-python-netology-hw"

echo "=== Начало развёртывания ==="

# 1. Клонируем репозиторий
echo "📦 Клонируем репозиторий..."
if [ ! -d "$PROJECT_DIR" ]; then
    sudo git clone "$REPO_URL" "$PROJECT_DIR"
    echo "✅ Репозиторий склонирован в $PROJECT_DIR"
else
    echo "ℹ️  Репозиторий уже существует, пропускаем клонирование"
fi

# 2. Переходим в директорию проекта
cd "$PROJECT_DIR" || exit 1

# 3. Добавляем пользователя ubuntu в группу docker
echo "🔧 Настраиваем права Docker..."
sudo usermod -aG docker ubuntu

# 4. Запускаем проект через docker compose
echo "🚀 Запускаем Docker контейнеры..."
sudo docker compose up -d

# 5. Ждём пока контейнеры поднимутся
echo "⏳ Ожидаем запуска сервисов (15 секунд)..."
sleep 15

# 6. Проверяем статус
echo ""
echo "=== 📊 Статус контейнеров ==="
sudo docker ps -a

# 7. Получаем внешний IP
EXTERNAL_IP=$(curl -s https://api.ipify.org)

echo ""
echo "=== ✅ Проект развёрнут! ==="
echo "🌐 Внешний IP: $EXTERNAL_IP"
echo ""
echo "📝 Проверьте работу приложения:"
echo "   curl http://${EXTERNAL_IP}:8090"
echo ""
echo "🔗 Или откройте в браузере:"
echo "   http://${EXTERNAL_IP}:8090"
echo ""
echo "=== Для проверки SQL подключитесь к БД: ==="
echo "docker exec -ti shvirtd-example-python-netology-hw-db-1 mysql -uroot -pYtReWq4321"