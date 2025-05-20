# Kıyafet Öneri ML Servisi

Bu servis, hava durumuna göre akıllı kıyafet önerileri sunan bir makine öğrenmesi API'sidir. Flutter uygulamasıyla entegre çalışır.

## Özellikler

- Hava durumuna göre akıllı kıyafet kombinasyonları önerme
- Renk uyumlarını analiz etme
- Mevsimsel ve sıcaklık bazlı filtreleme
- Local JSON verileriyle demo modu

## Kurulum

1. Gerekli Python paketlerini yükle:

```bash
pip install -r requirements.txt
```

2. Örnek verileri oluştur:

```bash
python data_generator.py
```

3. API'yi başlat:

```bash
python app.py
```

API varsayılan olarak `http://localhost:5000` adresinde çalışacaktır.

## API Endpointleri

### GET /
API durum bilgisini döndürür

### POST /api/recommend
Kıyafet önerisi talep et

**İstek formatı:**
```json
{
  "userId": "user1",
  "weather": {
    "temperature": 22.5,
    "condition": "sunny",
    "description": "Güneşli bir gün"
  }
}
```

**Yanıt formatı:**
```json
[
  {
    "id": "item1",
    "user_id": "user1",
    "name": "Beyaz T-Shirt",
    "type": "tShirt",
    "colors": ["#FFFFFF"],
    "seasons": ["summer", "spring"],
    "brand": "Nike",
    "image_url": "https://example.com/tshirt.jpg",
    "created_at": "2023-06-01T12:00:00.000Z",
    "updated_at": "2023-06-01T12:00:00.000Z"
  },
  {
    "id": "item2",
    "user_id": "user1",
    "name": "Mavi Jean",
    "type": "jeans",
    "colors": ["#0000FF"],
    "seasons": ["all"],
    "brand": "Levi's",
    "image_url": "https://example.com/jeans.jpg",
    "created_at": "2023-05-20T10:00:00.000Z",
    "updated_at": "2023-05-20T10:00:00.000Z"
  }
]
```

## Makine Öğrenmesi Algoritması

Bu servis, temel bir içerik tabanlı filtreleme algoritması kullanır:

1. Hava durumuna göre uygun kıyafetleri filtreler
2. Kıyafetleri kategorilere ayırır (üst giyim, alt giyim, ayakkabı, dış giyim)
3. Renk ve stil uyumlarını kosinüs benzerliği kullanarak hesaplar
4. En uyumlu kombinasyonu oluşturur

Not: Gerçek bir ML projesinde, kullanıcı etkileşimlerinden öğrenen bir model entegre edilebilir.

## Flutter Entegrasyonu

Flutter uygulaması, `MLRecommendationService` sınıfını kullanarak bu API'ye bağlanır. API geçici olarak kullanılamadığında, servis otomatik olarak demo moduna geçer. 