import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
import json
import os
import pickle
import random
from datetime import datetime

class OutfitRecommender:
    def __init__(self, model_path=None):
        self.model = self._create_new_model()
        self.last_recommendations = []  # Son önerileri sakla
        
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
        
        # Çoklu strateji ile farklı kombinler oluştur
        strategies = [
            self._strategy_weather_focused,
            self._strategy_color_harmony,
            self._strategy_style_based,
            self._strategy_random_creative
        ]
        
        # Rastgele bir strateji seç (ama son kullanılanı tekrar etme)
        available_strategies = [s for s in strategies if s.__name__ not in [r.get('strategy') for r in self.last_recommendations[-3:]]]
        if not available_strategies:
            available_strategies = strategies
            
        selected_strategy = random.choice(available_strategies)
        print(f"🎯 Seçilen strateji: {selected_strategy.__name__}")
        
        # Stratejiyi uygula
        outfit = selected_strategy(user_items, weather)
        
        # Sonucu kaydet
        self.last_recommendations.append({
            'strategy': selected_strategy.__name__,
            'timestamp': datetime.now().isoformat(),
            'outfit_count': len(outfit)
        })
        
        # Son 10 öneriyi sakla
        if len(self.last_recommendations) > 10:
            self.last_recommendations = self.last_recommendations[-10:]
        
        print(f"✅ Kombin oluşturuldu: {len(outfit)} parça")
        return outfit
    
    def _strategy_weather_focused(self, user_items, weather):
        """Hava durumu odaklı strateji"""
        print("🌤️ Hava durumu odaklı strateji kullanılıyor")
        
        temperature = weather['temperature']
        suitable_items = self._filter_by_weather(user_items, weather)
        
        if not suitable_items:
            suitable_items = user_items
            
        return self._build_basic_outfit(suitable_items, weather, strategy='best')
    
    def _strategy_color_harmony(self, user_items, weather):
        """Renk uyumu odaklı strateji"""
        print("🎨 Renk uyumu odaklı strateji kullanılıyor")
        
        # Önce hava durumuna uygun kıyafetleri filtrele
        suitable_items = self._filter_by_weather(user_items, weather)
        if not suitable_items:
            suitable_items = user_items
            
        # Kategorilere ayır
        tops = [item for item in suitable_items if self._is_upper_clothing(item)]
        bottoms = [item for item in suitable_items if self._is_lower_clothing(item)]
        shoes = [item for item in suitable_items if self._is_footwear(item)]
        outerwears = [item for item in suitable_items if self._is_outerwear(item)]
        
        outfit = []
        
        # Dominant rengi olan bir üst giyim seç
        if tops:
            # Renkli kıyafetleri öncelikle seç
            colorful_tops = [item for item in tops if len(item['colors']) > 0]
            if colorful_tops:
                base_item = random.choice(colorful_tops)
            else:
                base_item = random.choice(tops)
            outfit.append(base_item)
            print(f"🎨 Ana renk bazı: {base_item['name']} - {base_item['colors']}")
            
            # Bu renkle uyumlu alt giyim bul
            if bottoms:
                matching_bottom = self._find_color_matching_item(base_item, bottoms, diversity_mode=True)
                outfit.append(matching_bottom)
                
            # Uyumlu ayakkabı ekle
            if shoes:
                matching_shoe = self._find_color_matching_item(base_item, shoes, diversity_mode=True)
                outfit.append(matching_shoe)
            
            # Gerekirse dış giyim ekle
        if self._needs_outerwear(weather) and outerwears:
                # Nötr renk dış giyim tercih et
                neutral_outerwears = [item for item in outerwears 
                                    if any(color.lower() in ['#000000', '#ffffff', '#808080'] 
                                          for color in item['colors'])]
                if neutral_outerwears:
                    outfit.append(random.choice(neutral_outerwears))
                else:
                    outfit.append(random.choice(outerwears))
        
        return outfit
    
    def _strategy_style_based(self, user_items, weather):
        """Stil bazlı strateji (casual, formal, sporty)"""
        print("👔 Stil bazlı strateji kullanılıyor")
        
        # Rastgele bir stil seç
        styles = ['casual', 'formal', 'sporty']
        target_style = random.choice(styles)
        print(f"🎯 Hedef stil: {target_style}")
        
        # Hava durumuna uygun kıyafetleri filtrele
        suitable_items = self._filter_by_weather(user_items, weather)
        if not suitable_items:
            suitable_items = user_items
            
        # Stile uygun kıyafetleri seç
        style_items = self._filter_by_style(suitable_items, target_style)
        if not style_items:
            style_items = suitable_items
            
        return self._build_basic_outfit(style_items, weather, strategy='diverse')
    
    def _strategy_random_creative(self, user_items, weather):
        """Yaratıcı rastgele strateji"""
        print("🎲 Yaratıcı rastgele strateji kullanılıyor")
        
        # Hava durumuna uygun kıyafetleri filtrele
        suitable_items = self._filter_by_weather(user_items, weather)
        if not suitable_items:
            suitable_items = user_items
            
        # Tamamen rastgele seçim stratejisi kullan
        return self._build_basic_outfit(suitable_items, weather, strategy='random')
        
    def _filter_by_style(self, items, target_style):
        """Stile göre kıyafetleri filtrele"""
        style_mapping = {
            'casual': ['tShirt', 'jeans', 'shorts', 'shoes'],
            'formal': ['shirt', 'blouse', 'pants', 'skirt', 'dress', 'shoes'],
            'sporty': ['tShirt', 'shorts', 'shoes', 'jacket']
        }
        
        suitable_types = style_mapping.get(target_style, [])
        return [item for item in items if item['type'] in suitable_types]
    
    def _find_color_matching_item(self, reference_item, candidates, diversity_mode=False):
        """Renk uyumlu kıyafet bul (geliştirilmiş)"""
        if not candidates:
            return None
            
        ref_colors = reference_item['colors']
        scored_items = []
        
        for item in candidates:
            score = self._calculate_advanced_color_match(ref_colors, item['colors'])
            scored_items.append((item, score))
        
        scored_items.sort(key=lambda x: x[1], reverse=True)
        
        if diversity_mode:
            # Çeşitlilik için daha geniş aralıktan seç
            top_candidates = scored_items[:min(7, len(scored_items))]
        else:
            # En iyi 3'ü arasından rastgele seç
            top_candidates = scored_items[:min(3, len(scored_items))]
        
        return random.choice([item for item, _ in top_candidates])
    
    def _calculate_advanced_color_match(self, colors1, colors2):
        """Gelişmiş renk uyumu hesaplama"""
        if not colors1 or not colors2:
            return random.random()  # Rastgele skor ver
            
        match_score = 0
        
        for c1 in colors1:
            for c2 in colors2:
                # Aynı renk
                if c1.lower() == c2.lower():
                    match_score += 5
                    continue
                
                # Nötr renkler (siyah, beyaz, gri) her şeyle uyumlu
                neutral_colors = ['#000000', '#ffffff', '#808080', '#c0c0c0']
                if c1.lower() in neutral_colors or c2.lower() in neutral_colors:
                    match_score += 3
                
                # Komplementer renkler (basit kontrol)
                if self._are_complementary_colors(c1, c2):
                    match_score += 4
                
                # Analog renkler
                if self._are_analogous_colors(c1, c2):
                    match_score += 2
        
        # Normalize et ve rastgelelik ekle
        normalized_score = match_score / (len(colors1) * len(colors2)) if colors1 and colors2 else 0
        return normalized_score + random.uniform(-0.1, 0.1)  # Küçük rastgelelik
    
    def _are_complementary_colors(self, color1, color2):
        """Basit komplementer renk kontrolü"""
        # Basitleştirilmiş komplementer renk çiftleri
        complementary_pairs = [
            ('#ff0000', '#00ff00'),  # Kırmızı-Yeşil
            ('#0000ff', '#ffff00'),  # Mavi-Sarı
            ('#ff00ff', '#00ffff'),  # Magenta-Cyan
        ]
        
        c1, c2 = color1.lower(), color2.lower()
        return any((c1, c2) == pair or (c2, c1) == pair for pair in complementary_pairs)
    
    def _are_analogous_colors(self, color1, color2):
        """Basit analog renk kontrolü"""
        # Bu gerçek uygulamada HSV renk uzayında hesaplanmalı
        # Şimdilik basit bir yaklaşım
        return random.random() < 0.3  # %30 ihtimalle analog kabul et
    
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
        
    def _select_best_item(self, items, weather, strategy='best'):
        # Kıyafeti hava durumuna göre seç (temel)
        temperature = weather['temperature']
        
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
            
        # Strateji bazlı seçim
        scored_items.sort(key=lambda x: x[1], reverse=True)
        
        if strategy == 'best':
            # En yüksek puanlı kıyafeti seç
            max_score = scored_items[0][1]
            best_items = [item for item, score in scored_items if score == max_score]
            return random.choice(best_items)
        elif strategy == 'diverse':
            # Top 5'ten rastgele seç (çeşitlilik için)
            top_items = scored_items[:min(5, len(scored_items))]
            return random.choice([item for item, _ in top_items])
        elif strategy == 'random':
            # Tamamen rastgele seç
            return random.choice([item for item, _ in scored_items])
        elif strategy == 'worst_to_best':
            # En düşük puanlıdan başla (farklılık için)
            scored_items.reverse()
            bottom_items = scored_items[:min(3, len(scored_items))]
            return random.choice([item for item, _ in bottom_items])
        else:
            # Varsayılan: en iyi
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
    
    def _build_basic_outfit(self, suitable_items, weather, strategy='best'):
        """Temel kombin oluşturma algoritması"""
        # Kategorilere ayır
        tops = [item for item in suitable_items if self._is_upper_clothing(item)]
        bottoms = [item for item in suitable_items if self._is_lower_clothing(item)]
        shoes = [item for item in suitable_items if self._is_footwear(item)]
        outerwears = [item for item in suitable_items if self._is_outerwear(item)]
        
        print(f"👚 Üst giyim: {len(tops)}, 👖 Alt giyim: {len(bottoms)}, 👞 Ayakkabı: {len(shoes)}, 🧥 Dış giyim: {len(outerwears)}")
        
        outfit = []
        
        # Üst giyim ekle
        if tops:
            upper = self._select_best_item(tops, weather, strategy)
            outfit.append(upper)
            print(f"👚 Seçilen üst giyim: {upper['name']}")
        
        # Alt giyim ekle
        if bottoms:
            if outfit and strategy != 'random':  # Üst giyimle uyumlu alt giyim seç (random hariç)
                bottom = self._select_matching_item(outfit[0], bottoms)
            else:
                bottom = self._select_best_item(bottoms, weather, strategy)
            outfit.append(bottom)
            print(f"👖 Seçilen alt giyim: {bottom['name']}")
            
        # Dış giyim ekle (hava durumuna göre)
        if self._needs_outerwear(weather) and outerwears:
            if strategy == 'random':
                outerwear = random.choice(outerwears)
            else:
                outerwear = self._select_matching_item_for_outfit(outfit, outerwears)
            outfit.append(outerwear)
            print(f"🧥 Seçilen dış giyim: {outerwear['name']}")
            
        # Ayakkabı ekle
        if shoes:
            if strategy == 'random':
                shoe = random.choice(shoes)
            else:
                shoe = self._select_matching_item_for_outfit(outfit, shoes)
            outfit.append(shoe)
            print(f"👞 Seçilen ayakkabı: {shoe['name']}")
        
        return outfit 