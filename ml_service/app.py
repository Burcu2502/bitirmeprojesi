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
    
    # JSON dosyasından kullanıcı kıyafetlerini al
    all_items = load_data()
    user_items = [item for item in all_items if item['userId'] == user_id]
    
    # Eğer demo için kullanıcı bulunamazsa, ilk kullanıcıyı kullan
    if not user_items and all_items:
        user_id = all_items[0]['userId']
        user_items = [item for item in all_items if item['userId'] == user_id]
        print(f"Kullanıcı kıyafeti bulunamadı, demo kullanıcısı kullanılıyor: {user_id}")
    
    # Kombinleri öner
    recommendations = recommender.recommend(user_items, weather)
    
    # Debug
    print(f"Öneri oluşturuldu: {len(recommendations)} kıyafet")
    
    return jsonify(recommendations)

if __name__ == '__main__':
    print("🚀 Kıyafet Öneri API'si başlatılıyor...")
    print(f"📂 Veri klasörü: {DATA_DIR}")
    app.run(debug=True, host='0.0.0.0', port=5000) 