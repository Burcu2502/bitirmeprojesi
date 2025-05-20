import json
import random
import uuid
from datetime import datetime, timedelta
import os

def generate_clothing_items(num_items=200):
    types = ['tShirt', 'shirt', 'blouse', 'sweater', 'jacket', 'coat', 
             'jeans', 'pants', 'shorts', 'skirt', 'dress', 'shoes', 'boots']
    
    colors = [
        '#FF0000', '#00FF00', '#0000FF', '#FFFF00', '#FF00FF', '#00FFFF',
        '#000000', '#FFFFFF', '#808080', '#800000', '#808000', '#008000',
        '#800080', '#008080', '#000080', '#FFA500', '#A52A2A', '#FFC0CB'
    ]
    
    color_names = {
        '#FF0000': 'Kırmızı', '#00FF00': 'Yeşil', '#0000FF': 'Mavi',
        '#FFFF00': 'Sarı', '#FF00FF': 'Pembe', '#00FFFF': 'Turkuaz',
        '#000000': 'Siyah', '#FFFFFF': 'Beyaz', '#808080': 'Gri',
        '#800000': 'Bordo', '#808000': 'Zeytin yeşili', '#008000': 'Koyu yeşil',
        '#800080': 'Mor', '#008080': 'Çam yeşili', '#000080': 'Lacivert',
        '#FFA500': 'Turuncu', '#A52A2A': 'Kahverengi', '#FFC0CB': 'Açık pembe'
    }
    
    brands = ['Nike', 'Adidas', 'Zara', 'H&M', 'Mango', 'Lacoste', 'Tommy Hilfiger', 
              'Levi\'s', 'Calvin Klein', 'LCW', 'DeFacto', 'Koton', None]
    
    seasons = [['winter'], ['spring'], ['summer'], ['fall'], 
               ['winter', 'fall'], ['spring', 'summer'], ['all']]
    
    # Kullanıcı ID'leri
    user_ids = [f'user{i}' for i in range(1, 11)]
    
    # Kıyafet türlerine göre isim önerileri
    type_name_prefixes = {
        'tShirt': ['Rahat', 'Spor', 'Günlük', 'Baskılı', 'Düz', 'Renkli'],
        'shirt': ['Şık', 'Çizgili', 'Kareli', 'Klasik', 'Casual', 'Uzun kollu'],
        'blouse': ['Zarif', 'Şık', 'Desenli', 'Çiçekli', 'İpek', 'Dantel'],
        'sweater': ['Kalın', 'İnce', 'Boğazlı', 'V yaka', 'Sıcak', 'Örme'],
        'jacket': ['Spor', 'Kot', 'Deri', 'Hafif', 'Su geçirmez', 'Rüzgarlık'],
        'coat': ['Uzun', 'Yün', 'Kışlık', 'Kaşe', 'Kalın', 'Trençkot'],
        'jeans': ['Skinny', 'Regular', 'Straight', 'Yüksek bel', 'Yırtık', 'Kot'],
        'pants': ['Kumaş', 'Pileli', 'Chino', 'Slim fit', 'Jogger', 'Rahat'],
        'shorts': ['Kot', 'Spor', 'Plaj', 'Bermuda', 'Kargo', 'Kısa'],
        'skirt': ['Mini', 'Midi', 'Uzun', 'Pileli', 'Kalem', 'Kot'],
        'dress': ['Yazlık', 'Kokteyl', 'Günlük', 'Midi', 'Mini', 'Maksi'],
        'shoes': ['Spor', 'Klasik', 'Günlük', 'Rahat', 'Oxford', 'Loafer'],
        'boots': ['Kışlık', 'Yağmur', 'Postal', 'Kovboy', 'Topuklu', 'Chelsea']
    }
    
    items = []
    for i in range(num_items):
        # Kıyafet tipini seç
        item_type = random.choice(types)
        
        # Renkleri seç
        item_colors = [random.choice(colors) for _ in range(random.randint(1, 3))]
        
        # İsim oluştur
        color_name = color_names.get(item_colors[0], '')
        type_prefix = random.choice(type_name_prefixes.get(item_type, ['']))
        item_name = f"{type_prefix} {color_name} {item_type}"
        
        # Mevsimleri seç
        item_seasons = random.choice(seasons)
        
        # Kullanıcı seç
        user_id = random.choice(user_ids)
        
        # Oluşturma tarihi
        created_date = datetime.now() - timedelta(days=random.randint(0, 365))
        
        # Kıyafet nesnesi oluştur
        item = {
            'id': str(uuid.uuid4()),
            'userId': user_id,
            'name': item_name.strip(),
            'type': item_type,
            'colors': item_colors,
            'brand': random.choice(brands),
            'seasons': item_seasons,
            'occasion': random.choice(['casual', 'formal', 'sport', 'special']),
            'imageUrl': f'https://picsum.photos/200/300?random={i}',
            'createdAt': created_date.isoformat(),
        }
        items.append(item)
    
    return items

def generate_outfits(items, num_outfits=50):
    outfits = []
    
    # Kullanıcı bazında gruplama yap
    users = {}
    for item in items:
        user_id = item['userId']
        if user_id not in users:
            users[user_id] = []
        users[user_id].append(item)
    
    # Her kullanıcı için kombin oluştur
    for user_id, user_items in users.items():
        # Her kullanıcı için yaklaşık 5 kombin oluştur
        for i in range(5):
            # Kategori bazında kıyafetleri ayır
            tops = [item for item in user_items if item['type'] in ['tShirt', 'shirt', 'blouse', 'sweater']]
            bottoms = [item for item in user_items if item['type'] in ['jeans', 'pants', 'shorts', 'skirt']]
            shoes = [item for item in user_items if item['type'] in ['shoes', 'boots']]
            outerwears = [item for item in user_items if item['type'] in ['jacket', 'coat']]
            
            # Kombin için kıyafet seç
            outfit_items = []
            if tops:
                outfit_items.append(random.choice(tops))
            if bottoms:
                outfit_items.append(random.choice(bottoms))
            if shoes:
                outfit_items.append(random.choice(shoes))
            if outerwears and random.random() < 0.5:  # %50 ihtimalle dış giyim ekle
                outfit_items.append(random.choice(outerwears))
            
            if len(outfit_items) > 1:  # En az 2 parça olmalı
                # Kombin için mevsim belirle
                outfit_seasons = []
                for item in outfit_items:
                    outfit_seasons.extend(item['seasons'])
                # En sık tekrar eden mevsimi bul
                from collections import Counter
                season_counter = Counter(outfit_seasons)
                common_seasons = [season for season, count in season_counter.most_common(2)]
                
                # Hava durumu koşulları
                weather_conditions = random.choice([
                    ['sunny'], ['rainy'], ['cloudy'], ['snowy'], 
                    ['sunny', 'cloudy'], ['rainy', 'cloudy']
                ])
                
                # Kombin oluştur
                outfit = {
                    'id': str(uuid.uuid4()),
                    'userId': user_id,
                    'name': f'Kombin {i+1}',
                    'description': 'Örnek kombin açıklaması',
                    'clothingItemIds': [item['id'] for item in outfit_items],
                    'seasons': common_seasons,
                    'weatherConditions': weather_conditions,
                    'occasion': random.choice(['casual', 'formal', 'sport', 'special']),
                    'createdAt': datetime.now().isoformat(),
                    'updatedAt': datetime.now().isoformat(),
                }
                outfits.append(outfit)
    
    return outfits

if __name__ == '__main__':
    print("🚀 Veri üretmeye başlanıyor...")
    
    # Veri klasörü kontrolü
    data_dir = os.path.join(os.path.dirname(__file__), 'data')
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)
        print(f"📁 {data_dir} klasörü oluşturuldu")
    
    # Kıyafet verisi oluştur
    items = generate_clothing_items(200)
    print(f"👕 {len(items)} kıyafet oluşturuldu")
    
    # Kombin verisi oluştur
    outfits = generate_outfits(items, 50)
    print(f"👚 {len(outfits)} kombin oluşturuldu")
    
    # Verileri kaydet
    with open(os.path.join(data_dir, 'clothing_items.json'), 'w', encoding='utf-8') as f:
        json.dump(items, f, indent=2, ensure_ascii=False)
    
    with open(os.path.join(data_dir, 'outfits.json'), 'w', encoding='utf-8') as f:
        json.dump(outfits, f, indent=2, ensure_ascii=False)
    
    print("✅ Veriler başarıyla kaydedildi!")
    print(f"📂 clothing_items.json: {len(items)} kıyafet")
    print(f"📂 outfits.json: {len(outfits)} kombin") 