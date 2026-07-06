#!/usr/bin/env bash

# СТОП при любых ошибках
set -e

# ==========================================
# КОНФИГУРАЦИЯ
# ==========================================
KEY_ID="A731DD12"
REPO_NAME="DESERT OS Software Repository"
CODENAME="resolute" # База Ubuntu 26.04
COMPONENTS="main"
ARCHITECTURES="amd64"

echo "=== 1. Генерация индексных файлов Packages ==="
# Сканируем директорию на наличие .deb файлов и создаем индекс
dpkg-scanpackages --multiversion . /dev/null > Packages
gzip -9fk Packages

echo "=== 2. Генерация главного файла Release ==="
# Формируем метаданные репозитория
cat <<EOF > Release
Origin: $REPO_NAME
Label: $REPO_NAME
Suite: $CODENAME
Codename: $CODENAME
Architectures: $ARCHITECTURES
Components: $COMPONENTS
Description: Official APT repository for DESERT OS Linux applications
EOF

# Добавляем контрольные суммы файлов Packages в релиз
echo "MD5Sum:" >> Release
echo " $(md5sum Packages | cut -d' ' -f1) $(stat -c%s Packages) Packages" >> Release
echo " $(md5sum Packages.gz | cut -d' ' -f1) $(stat -c%s Packages.gz) Packages.gz" >> Release

echo "SHA1:" >> Release
echo " $(sha1sum Packages | cut -d' ' -f1) $(stat -c%s Packages) Packages" >> Release
echo " $(sha1sum Packages.gz | cut -d' ' -f1) $(stat -c%s Packages.gz) Packages.gz" >> Release

echo "SHA256:" >> Release
echo " $(sha256sum Packages | cut -d' ' -f1) $(stat -c%s Packages) Packages" >> Release
echo " $(sha256sum Packages.gz | cut -d' ' -f1) $(stat -c%s Packages.gz) Packages.gz" >> Release

echo "=== 3. Подписание репозитория GPG ключом ==="
# Удаляем старые подписи, если они были
rm -f Release.gpg InRelease

# Создаем разделенную и встроенную подписи (требование современных APT)
gpg --default-key "$KEY_ID" --clearsign -o InRelease Release
gpg --default-key "$KEY_ID" -abs -o Release.gpg Release

echo "=== 4. Отправка изменений на GitHub ==="
git add .
git commit -m "Update repository packages and metadata"
git push origin main

echo "=== Готово! Репозиторий успешно обновлен на GitHub Pages ==="
