#!/bin/bash

# Renk kodları
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Kıyafet Öneri ML Servisi Demo     ${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Python kontrol
if ! command -v python3 &> /dev/null
then
    echo -e "${RED}Python bulunamadı! Python 3 kurulu olmalı.${NC}"
    exit 1
fi

# Gerekli kütüphaneleri kur
echo -e "${YELLOW}1. Gerekli Python kütüphaneleri kuruluyor...${NC}"
pip install -r requirements.txt
echo -e "${GREEN}✓ Kütüphaneler kuruldu${NC}"
echo

# Veri klasörünü kontrol et
if [ ! -d "data" ]; then
    mkdir -p data
    echo -e "${YELLOW}data/ klasörü oluşturuldu${NC}"
fi

# Örnek verileri oluştur
echo -e "${YELLOW}2. Örnek veri üretiliyor...${NC}"
python3 data_generator.py
echo -e "${GREEN}✓ Örnek veriler oluşturuldu${NC}"
echo 

# API'yi başlat
echo -e "${YELLOW}3. API başlatılıyor...${NC}"
echo -e "${BLUE}API şu adreste çalışacak: http://localhost:5000${NC}"
echo -e "${BLUE}API'yi durdurmak için Ctrl+C tuşlarına basın${NC}"
echo
python3 app.py 