import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
import json
import os
import pickle
import random

class OutfitRecommender:
    def __init__(self, model_path=None):
        self.model = self._create_new_model()
        
    def _create_new_model(self):
        # Basit bir model yapısı
        return {'vectors': {}, 'clusters': {}}
        
    def recommend(self, user_items, weather):
        # Eğer hiç kıyafet yoksa boş liste döndür
        if not user_items:
            print("⚠️ Kullanıcının kıyafeti bulunamadı!")
            return []
            
        print(f"🌡️ Hava durumu: {weather['temperature']}°C, {weather['condition']}")
        print(f"👕 Toplam kıyafet sayısı: {len(user_items)}")
        
        # Hava durumuna göre uygun kıyafetleri filtrele
        suitable_items = self._filter_by_weather(user_items, weather)
        print(f"🔍 Hava durumuna uygun kıyafet sayısı: {len(suitable_items)}")
        
        if not suitable_items:
            print("⚠️ Hava durumuna uygun kıyafet bulunamadı!")
            return []
        
        # Kıyafetleri kategorilerine göre ayır
        tops = [item for item in suitable_items if self._is_upper_clothing(item)]
        bottoms = [item for item in suitable_items if self._is_lower_clothing(item)]
        shoes = [item for item in suitable_items if self._is_footwear(item)]
        outerwears = [item for item in suitable_items if self._is_outerwear(item)]
        
        print(f"👚 Üst giyim: {len(tops)}, 👖 Alt giyim: {len(bottoms)}, 👞 Ayakkabı: {len(shoes)}, 🧥 Dış giyim: {len(outerwears)}")
        
        # En uygun kombinasyonu bul
        outfit = []
        
        # Üst giyim ekle
        if tops:
            upper = self._select_best_item(tops, weather)
            outfit.append(upper)
            print(f"👚 Seçilen üst giyim: {upper['name']}")
        
        # Alt giyim ekle
        if bottoms:
            if outfit:  # Üst giyimle uyumlu alt giyim seç
                bottom = self._select_matching_item(outfit[0], bottoms)
            else:
                bottom = self._select_best_item(bottoms, weather)
            outfit.append(bottom)
            print(f"👖 Seçilen alt giyim: {bottom['name']}")
            
        # Dış giyim ekle (hava durumuna göre)
        if self._needs_outerwear(weather) and outerwears:
            outerwear = self._select_matching_item_for_outfit(outfit, outerwears)
            outfit.append(outerwear)
            print(f"🧥 Seçilen dış giyim: {outerwear['name']}")
            
        # Ayakkabı ekle
        if shoes:
            shoe = self._select_matching_item_for_outfit(outfit, shoes)
            outfit.append(shoe)
            print(f"👞 Seçilen ayakkabı: {shoe['name']}")
            
        print(f"✅ Kombin oluşturuldu: {len(outfit)} parça")
        
        return outfit
        
    def _filter_by_weather(self, items, weather):
        temperature = weather['temperature']
        condition = weather['condition']
        
        # Sıcaklık ve hava durumuna göre filtrele
        suitable_items = []
        for item in items:
            # Kıyafet türüne göre mevsimsel uygunluk
            if temperature < 10 and ('winter' in item['seasons'] or 'fall' in item['seasons']):
                suitable_items.append(item)
            elif temperature < 20 and ('fall' in item['seasons'] or 'spring' in item['seasons']):
                suitable_items.append(item)
            elif temperature >= 20 and ('summer' in item['seasons'] or 'spring' in item['seasons']):
                suitable_items.append(item)
            elif 'all' in item['seasons']:
                suitable_items.append(item)
        
        # Eğer hiç uygun kıyafet yoksa, tüm kıyafetleri döndür
        return suitable_items if suitable_items else items
        
    def _select_best_item(self, items, weather):
        # Kıyafeti hava durumuna göre seç (temel)
        
        # Kıyafetleri puanla
        scored_items = []
        for item in items:
            score = 0
            
            # Mevsim uyumluluğu
            if temperature < 10 and 'winter' in item['seasons']:
                score += 3
            elif temperature < 20 and ('fall' in item['seasons'] or 'spring' in item['seasons']):
                score += 2
            elif temperature >= 20 and 'summer' in item['seasons']:
                score += 3
                
            # Tür uyumluluğu
            if temperature < 10 and item['type'] in ['sweater', 'pants', 'jeans']:
                score += 2
            elif temperature >= 20 and item['type'] in ['tShirt', 'shorts', 'skirt']:
                score += 2
                
            scored_items.append((item, score))
            
        # En yüksek puanlı kıyafeti seç
        scored_items.sort(key=lambda x: x[1], reverse=True)
        
        # Eğer eşit puanlı kıyafetler varsa rastgele seç
        max_score = scored_items[0][1]
        best_items = [item for item, score in scored_items if score == max_score]
        
        return random.choice(best_items)
        
    def _select_matching_item(self, reference_item, candidate_items):
        # Renk uyumuna göre eşleşen kıyafeti seç
        if not candidate_items:
            return None
            
        # Referans kıyafetin renklerini al
        ref_colors = reference_item['colors']
        
        # Adayları puanla
        scored_items = []
        for item in candidate_items:
            # Renk uyumunu kontrol et
            color_score = self._calculate_color_match(ref_colors, item['colors'])
            scored_items.append((item, color_score))
            
        # En yüksek puanlı kıyafeti seç
        scored_items.sort(key=lambda x: x[1], reverse=True)
        
        # Eğer eşit puanlı kıyafetler varsa rastgele seç
        max_score = scored_items[0][1]
        best_items = [item for item, score in scored_items if score == max_score]
        
        return random.choice(best_items)
        
    def _select_matching_item_for_outfit(self, outfit, candidate_items):
        # Mevcut kombinle uyumlu kıyafet seç
        if not candidate_items or not outfit:
            return random.choice(candidate_items) if candidate_items else None
            
        # Adayları puanla
        scored_items = []
        for item in candidate_items:
            total_score = 0
            
            # Her bir kombin parçasıyla uyumu kontrol et
            for outfit_item in outfit:
                color_score = self._calculate_color_match(outfit_item['colors'], item['colors'])
                total_score += color_score
                
            # Ortalama skoru hesapla
            avg_score = total_score / len(outfit)
            scored_items.append((item, avg_score))
            
        # En yüksek puanlı kıyafeti seç
        scored_items.sort(key=lambda x: x[1], reverse=True)
        
        # Eğer eşit puanlı kıyafetler varsa rastgele seç
        top_items = scored_items[:3] if len(scored_items) >= 3 else scored_items
        return random.choice([item for item, _ in top_items])
        
    def _calculate_color_match(self, colors1, colors2):
        if not colors1 or not colors2:
            return 0
            
        # Basit renk uyumu hesaplama
        # Gerçek uygulamada daha gelişmiş renk teorisi kullanılmalı
        match_score = 0
        
        # Aynı renkleri kontrol et
        for c1 in colors1:
            for c2 in colors2:
                if c1.lower() == c2.lower():
                    match_score += 3  # Tam eşleşme
                    continue
                    
                # Temel renk uyumları (basitleştirilmiş)
                # Siyah-beyaz her renkle uyumlu
                if c1.lower() in ['#000000', '#ffffff'] or c2.lower() in ['#000000', '#ffffff']:
                    match_score += 2
                
        return match_score / (len(colors1) * len(colors2)) * 10  # Normalize
    
    def _is_upper_clothing(self, item):
        upper_types = ['tShirt', 'shirt', 'blouse', 'sweater']
        return item['type'] in upper_types
    
    def _is_lower_clothing(self, item):
        lower_types = ['jeans', 'pants', 'shorts', 'skirt', 'dress']
        return item['type'] in lower_types
    
    def _is_footwear(self, item):
        footwear_types = ['shoes', 'boots']
        return item['type'] in footwear_types
        
    def _is_outerwear(self, item):
        outerwear_types = ['jacket', 'coat']
        return item['type'] in outerwear_types
        
    def _needs_outerwear(self, weather):
        # Dış giyim gerekiyor mu?
        temperature = weather['temperature']
        condition = weather['condition'].lower()
        
        # Soğuk hava veya yağmurlu/karlı hava
        return temperature < 15 or any(c in condition.lower() for c in ['rain', 'snow', 'yağmur', 'kar']) 