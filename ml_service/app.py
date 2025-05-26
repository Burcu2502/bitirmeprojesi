from flask import Flask, request, jsonify
from flask_cors import CORS
import json
import os
from models.outfit_model import OutfitRecommender

app = Flask(__name__)
CORS(app) 

# Verileri yükle
DATA_DIR = os.path.join(os.path.dirname(__file__), 'data')

def load_data():
    try:
        with open(os.path.join(DATA_DIR, 'clothing_items.json'), 'r', encoding='utf-8') as f:
            clothing_items = json.load(f)
        return clothing_items
    except FileNotFoundError:
        print("Veri dosyası bulunamadı! Lütfen data_generator.py'ı çalıştırın.")
        return []

# Model yükleme
recommender = OutfitRecommender()

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "status": "success",
        "message": "Kıyafet Öneri API'si çalışıyor",
        "endpoints": {
            "/api/recommend": "POST - Kıyafet önerisi almak için"
        }
    })

@app.route('/api/recommend', methods=['POST'])
def recommend_outfit():
    data = request.json
    user_id = data.get('userId')
    weather = data.get('weather')
    user_clothing_items = data.get('userClothingItems', [])
    
    print(f"📥 Tek öneri isteği - Kullanıcı: {user_id}")
    print(f"👕 Flutter'dan gelen kıyafet sayısı: {len(user_clothing_items)}")
    
    # Flutter'dan gelen kullanıcının gerçek kıyafetlerini kullan
    if user_clothing_items:
        user_items = user_clothing_items
        print("✅ Kullanıcının gerçek kıyafetleri kullanılıyor")
    else:
        # Katalog modu: JSON dosyasından demo kıyafetleri al (genel katalog)
        print("🏪 Katalog modu: Demo kıyafetleri kullanılıyor (genel katalog)")
        all_items = load_data()
        
        # Tüm demo kıyafetleri kullan (sadece bir kullanıcıya ait değil)
        if all_items:
            # İlk kullanıcının kıyafetlerini kullan (demo için)
            demo_user_id = all_items[0]['userId']
            user_items = [item for item in all_items if item['userId'] == demo_user_id]
            print(f"📦 Demo katalog kullanıcısı: {demo_user_id}, Kıyafet sayısı: {len(user_items)}")
        else:
            user_items = []
    
    # Kombinleri öner
    recommendations = recommender.recommend(user_items, weather)
    
    # Debug
    print(f"✅ Öneri oluşturuldu: {len(recommendations)} kıyafet")
    
    return jsonify(recommendations)

@app.route('/api/recommend-multiple', methods=['POST'])
def recommend_multiple_outfits():
    """4 farklı strateji ile çoklu kombin önerileri"""
    try:
        data = request.json
        user_id = data.get('userId')
        weather = data.get('weather')
        user_clothing_items = data.get('userClothingItems', [])
        
        print(f"📥 Çoklu öneri isteği - Kullanıcı: {user_id}")
        print(f"🌤️ Hava durumu: {weather}")
        print(f"👕 Flutter'dan gelen kıyafet sayısı: {len(user_clothing_items)}")
        
        # Flutter'dan gelen kullanıcının gerçek kıyafetlerini kullan
        if user_clothing_items:
            user_items = user_clothing_items
            print("✅ Kullanıcının gerçek kıyafetleri kullanılıyor")
        else:
            # Katalog modu: JSON dosyasından demo kıyafetleri al (genel katalog)
            print("🏪 Katalog modu: Demo kıyafetleri kullanılıyor (genel katalog)")
            all_items = load_data()
            
            # Tüm demo kıyafetleri kullan (sadece bir kullanıcıya ait değil)
            if all_items:
                # İlk kullanıcının kıyafetlerini kullan (demo için)
                demo_user_id = all_items[0]['userId']
                user_items = [item for item in all_items if item['userId'] == demo_user_id]
                print(f"📦 Demo katalog kullanıcısı: {demo_user_id}, Kıyafet sayısı: {len(user_items)}")
            else:
                user_items = []
        
        if not user_items:
            print("⚠️ Hiç kıyafet bulunamadı")
            return jsonify([])
        
        print(f"🎯 İşlenecek kıyafet sayısı: {len(user_items)}")
        
        # Kıyafet detaylarını logla
        for i, item in enumerate(user_items[:3]):  # İlk 3 kıyafeti göster
            print(f"  {i+1}. {item.get('name', 'İsimsiz')} - {item.get('type', 'Tip yok')}")
        
        # 4 farklı strateji ile öneriler oluştur
        strategies = [
            ('weather_focused', 'AI Hava Durumu Önerisi', 'Bugünkü hava durumuna özel AI önerisi'),
            ('color_harmony', 'AI Renk Uyumu Önerisi', 'Renk teorisi ile uyumlu AI kombinasyonu'),
            ('style_based', 'AI Stil Önerisi', 'Stil analizi ile oluşturulan AI önerisi'),
            ('random_creative', 'AI Yaratıcı Önerisi', 'Yaratıcı AI algoritması ile özel kombin')
        ]
        
        recommendations = []
        
        for strategy_name, title, description in strategies:
            try:
                if strategy_name == 'weather_focused':
                    outfit = recommender._strategy_weather_focused(user_items, weather)
                elif strategy_name == 'color_harmony':
                    outfit = recommender._strategy_color_harmony(user_items, weather)
                elif strategy_name == 'style_based':
                    outfit = recommender._strategy_style_based(user_items, weather)
                elif strategy_name == 'random_creative':
                    outfit = recommender._strategy_random_creative(user_items, weather)
                
                if outfit:
                    recommendations.append({
                        'title': title,
                        'description': description,
                        'strategy': strategy_name,
                        'items': outfit
                    })
                    print(f"✅ {strategy_name} stratejisi: {len(outfit)} parça")
                else:
                    print(f"⚠️ {strategy_name} stratejisi boş döndü")
                    
            except Exception as e:
                print(f"❌ {strategy_name} stratejisi hatası: {e}")
                continue
        
        print(f"🎯 Toplam {len(recommendations)} strateji önerisi oluşturuldu")
        return jsonify(recommendations)
        
    except Exception as e:
        print(f"❌ Çoklu öneri API hatası: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("🚀 Kıyafet Öneri API'si başlatılıyor...")
    print(f"📂 Veri klasörü: {DATA_DIR}")
    app.run(debug=True, host='0.0.0.0', port=5000) 