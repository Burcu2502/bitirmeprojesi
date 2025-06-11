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
        self.last_recommendations = []
        
    def _create_new_model(self):
        return {'vectors': {}, 'clusters': {}}
        
    def recommend(self, user_items, weather):
        if not user_items:
            print("⚠️ Kullanıcının kıyafeti bulunamadı!")
            return []
            
        print(f"🌡️ Hava durumu: {weather['temperature']}°C, {weather['condition']}")
        print(f"👕 Toplam kıyafet sayısı: {len(user_items)}")
        
        # Çoklu strateji ile kombinler oluştur
        strategies = [
            self._strategy_weather_focused,
            self._strategy_color_harmony,
            self._strategy_style_based,
            self._strategy_random_creative
        ]
        
        selected_strategy = random.choice(strategies)
        print(f"🎯 Seçilen strateji: {selected_strategy.__name__}")
        
        outfit = selected_strategy(user_items, weather)
        
        self.last_recommendations.append({
            'strategy': selected_strategy.__name__,
            'timestamp': datetime.now().isoformat(),
            'outfit_count': len(outfit)
        })
        
        if len(self.last_recommendations) > 10:
            self.last_recommendations = self.last_recommendations[-10:]
        
        print(f"✅ Kombin oluşturuldu: {len(outfit)} parça")
        return outfit
    
    def _strategy_weather_focused(self, user_items, weather):
        """Hava durumu odaklı strateji"""
        print("🌤️ Hava durumu odaklı strateji")
        
        suitable_items = self._filter_by_weather(user_items, weather)
        if not suitable_items:
            suitable_items = user_items
        
        return self._build_complete_outfit(suitable_items, weather, 'weather')
    
    def _strategy_color_harmony(self, user_items, weather):
        """Renk uyumu odaklı strateji"""
        print("🎨 Renk uyumu odaklı strateji")
        
        suitable_items = self._filter_by_weather(user_items, weather)
        if not suitable_items:
            suitable_items = user_items
        
        return self._build_complete_outfit(suitable_items, weather, 'color')
    
    def _strategy_style_based(self, user_items, weather):
        """Stil bazlı strateji"""
        print("👔 Stil bazlı strateji")
        
        styles = ['casual', 'formal', 'sporty']
        target_style = random.choice(styles)
        print(f"🎯 Hedef stil: {target_style}")
        
        suitable_items = self._filter_by_weather(user_items, weather)
        if not suitable_items:
            suitable_items = user_items
            
        style_items = self._filter_by_style(suitable_items, target_style)
        if not style_items:
            style_items = suitable_items
            
        return self._build_complete_outfit(style_items, weather, 'style', target_style)
    
    def _strategy_random_creative(self, user_items, weather):
        """Yaratıcı rastgele strateji"""
        print("🎲 Yaratıcı rastgele strateji")
        
        suitable_items = self._filter_by_weather(user_items, weather)
        if not suitable_items:
            suitable_items = user_items
            
        return self._build_complete_outfit(suitable_items, weather, 'creative')
    
    def _build_complete_outfit(self, items, weather, strategy_type, style=None):
        """Tüm kıyafet tiplerini destekleyen kombin oluşturucu"""
        
        # Kategorilere ayır
        dresses = [item for item in items if self._is_dress(item)]
        tops = [item for item in items if self._is_top(item)]
        bottoms = [item for item in items if self._is_bottom(item)]
        shoes = [item for item in items if self._is_shoes(item)]
        outerwear = [item for item in items if self._is_outerwear(item)]
        accessories = [item for item in items if self._is_accessory(item)]
        
        print(f"📊 Kategoriler - Elbise:{len(dresses)}, Üst:{len(tops)}, Alt:{len(bottoms)}, Ayakkabı:{len(shoes)}, Dış:{len(outerwear)}, Aksesuar:{len(accessories)}")
        
        outfit = []
        
        # 1. Ana parça seçimi (Elbise vs Normal kombin)
        if dresses and (strategy_type == 'creative' and random.random() < 0.4 or len(tops) == 0 or len(bottoms) == 0):
            # Elbise seç
            dress = self._select_item_by_strategy(dresses, weather, strategy_type, style)
            outfit.append(dress)
            print(f"👗 Elbise seçildi: {dress['name']}")
        else:
            # Normal kombin: üst + alt
            if tops:
                top = self._select_item_by_strategy(tops, weather, strategy_type, style)
                outfit.append(top)
                print(f"👕 Üst giyim: {top['name']}")
                
            if bottoms:
                if strategy_type == 'color' and outfit:
                    bottom = self._find_color_matching_item(outfit[0], bottoms)
                else:
                    bottom = self._select_item_by_strategy(bottoms, weather, strategy_type, style)
                outfit.append(bottom)
                print(f"👖 Alt giyim: {bottom['name']}")
        
        # 2. Ayakkabı ekle
        if shoes:
            if strategy_type == 'color' and outfit:
                shoe = self._find_color_matching_item(outfit[0], shoes)
            else:
                shoe = self._select_item_by_strategy(shoes, weather, strategy_type, style)
            outfit.append(shoe)
            print(f"👞 Ayakkabı: {shoe['name']}")
        
        # 3. Dış giyim (hava durumuna göre)
        if self._needs_outerwear(weather) and outerwear:
            if strategy_type == 'color' and outfit:
                outer = self._find_neutral_or_matching(outfit, outerwear)
            else:
                outer = self._select_item_by_strategy(outerwear, weather, strategy_type, style)
            outfit.append(outer)
            print(f"🧥 Dış giyim: {outer['name']}")
        
        # 4. Aksesuar ekle
        if accessories:
            selected_accessories = self._select_accessories(accessories, weather, strategy_type, style, outfit)
            outfit.extend(selected_accessories)
            for acc in selected_accessories:
                print(f"💍 Aksesuar: {acc['name']}")
        
        return outfit
    
    def _select_item_by_strategy(self, items, weather, strategy_type, style=None):
        """Stratejiye göre kıyafet seç"""
        if not items:
            return None
            
        if strategy_type == 'weather':
            return self._select_weather_appropriate(items, weather)
        elif strategy_type == 'color':
            # Renk stratejisi için renkli kıyafetleri tercih et
            colorful_items = [item for item in items if len(item['colors']) > 0]
            return random.choice(colorful_items if colorful_items else items)
        elif strategy_type == 'style':
            return self._select_style_appropriate(items, style, weather)
        elif strategy_type == 'creative':
            return random.choice(items)
        else:
            return random.choice(items)
    
    def _select_weather_appropriate(self, items, weather):
        """Hava durumuna en uygun kıyafeti seç"""
        temperature = weather['temperature']
        scored_items = []
        
        for item in items:
            score = 0
            
            # Sıcaklık uyumluluğu
            if temperature < 10:
                if 'winter' in item['seasons'] or 'fall' in item['seasons']:
                    score += 3
                if item['type'] in ['sweater', 'coat', 'boots', 'jeans', 'pants']:
                    score += 2
            elif temperature < 20:
                if 'spring' in item['seasons'] or 'fall' in item['seasons']:
                    score += 3
                if item['type'] in ['shirt', 'blouse', 'jacket', 'jeans', 'pants']:
                    score += 2
            else:
                if 'summer' in item['seasons'] or 'spring' in item['seasons']:
                    score += 3
                if item['type'] in ['tShirt', 'shorts', 'skirt', 'dress']:
                    score += 2
            
            # Mevsim bonus
            if 'all' in item['seasons']:
                score += 1
                
            scored_items.append((item, score))
        
        scored_items.sort(key=lambda x: x[1], reverse=True)
        max_score = scored_items[0][1]
        best_items = [item for item, score in scored_items if score == max_score]
        
        return random.choice(best_items)
    
    def _select_style_appropriate(self, items, style, weather):
        """Stile uygun kıyafet seç"""
        style_mapping = {
            'casual': ['tShirt', 'jeans', 'shorts', 'shoes', 'jacket', 'accessory', 'hat'],
            'formal': ['shirt', 'blouse', 'pants', 'skirt', 'dress', 'shoes', 'boots', 'coat', 'accessory'],
            'sporty': ['tShirt', 'shorts', 'shoes', 'jacket', 'hat', 'accessory']
        }
        
        suitable_types = style_mapping.get(style, [])
        style_items = [item for item in items if item['type'] in suitable_types]
        
        if style_items:
            return self._select_weather_appropriate(style_items, weather)
        else:
            return self._select_weather_appropriate(items, weather)
    
    def _select_accessories(self, accessories, weather, strategy_type, style, outfit):
        """Aksesuar seçimi - Aksesuar varsa mutlaka ekle!"""
        if not accessories:
            print("⚠️ Hiç aksesuar yok!")
            return []
        
        print(f"🔍 Aksesuar seçimi: {len(accessories)} aksesuar mevcut")
        for acc in accessories:
            print(f"   - {acc['name']} ({acc['type']})")
        
        selected = []
        temperature = weather['temperature']
        condition = weather['condition'].lower()
        
        print(f"🌡️ Sıcaklık: {temperature}°C, Durum: {condition}, Stil: {style}")
        
        # TEMEL KURAL: Her durumda en az 1 aksesuar ekle!
        print("✨ Temel aksesuar ekleniyor...")
        selected.append(random.choice(accessories))
        print(f"✅ Temel aksesuar: {selected[-1]['name']} eklendi")
        
        # BONUS: Hava durumuna göre ek aksesuarlar
        if temperature < 10:
            # Soğukta şapka/bere/atkı
            warm_accessories = [item for item in accessories if item['type'] in ['hat', 'scarf'] and item not in selected]
            if warm_accessories:
                selected.append(random.choice(warm_accessories))
                print(f"🧣 Soğuk hava bonus: {selected[-1]['name']} eklendi")
        
        # BONUS: Yağmurlu havada şapka
        if 'rain' in condition:
            hats = [item for item in accessories if item['type'] == 'hat' and item not in selected]
            if hats:
                selected.append(random.choice(hats))
                print(f"☔ Yağmur bonus: {selected[-1]['name']} eklendi")
        
        # BONUS: Yaratıcı modda 2. aksesuar
        if strategy_type == 'creative' and len(accessories) > 1 and random.random() < 0.6:
            remaining = [acc for acc in accessories if acc not in selected]
            if remaining:
                selected.append(random.choice(remaining))
                print(f"🎨 Yaratıcı bonus: {selected[-1]['name']} eklendi")
        
        print(f"✅ Toplam {len(selected)} aksesuar seçildi")
        return selected
    
    def _find_color_matching_item(self, reference_item, candidates):
        """Renk uyumlu kıyafet bul"""
        if not candidates:
            return None
            
        ref_colors = reference_item['colors']
        scored_items = []
        
        for item in candidates:
            score = self._calculate_color_match(ref_colors, item['colors'])
            scored_items.append((item, score))
        
        scored_items.sort(key=lambda x: x[1], reverse=True)
        top_candidates = scored_items[:min(3, len(scored_items))]
        
        return random.choice([item for item, _ in top_candidates])
    
    def _find_neutral_or_matching(self, outfit, candidates):
        """Nötr veya uyumlu renk bul"""
        if not candidates:
            return None
            
        # Önce nötr renkli olanları ara
        neutral_items = []
        for item in candidates:
            for color in item['colors']:
                if color.lower() in ['#000000', '#ffffff', '#808080', '#c0c0c0']:
                    neutral_items.append(item)
                    break
        
        if neutral_items:
            return random.choice(neutral_items)
        else:
            return self._find_color_matching_item(outfit[0], candidates)
    
    def _calculate_color_match(self, colors1, colors2):
        """Renk uyumu hesapla"""
        if not colors1 or not colors2:
            return 0
            
        match_score = 0
        
        for c1 in colors1:
            for c2 in colors2:
                if c1.lower() == c2.lower():
                    match_score += 5
                elif c1.lower() in ['#000000', '#ffffff', '#808080'] or c2.lower() in ['#000000', '#ffffff', '#808080']:
                    match_score += 3
                else:
                    match_score += 1
        
        return match_score / (len(colors1) * len(colors2)) if colors1 and colors2 else 0
    
    def _filter_by_weather(self, items, weather):
        """Hava durumuna göre filtrele"""
        temperature = weather['temperature']
        suitable_items = []
        
        for item in items:
            if temperature < 10 and ('winter' in item['seasons'] or 'fall' in item['seasons']):
                suitable_items.append(item)
            elif temperature < 20 and ('fall' in item['seasons'] or 'spring' in item['seasons']):
                suitable_items.append(item)
            elif temperature >= 20 and ('summer' in item['seasons'] or 'spring' in item['seasons']):
                suitable_items.append(item)
            elif 'all' in item['seasons']:
                suitable_items.append(item)
        
        return suitable_items if suitable_items else items
    
    def _filter_by_style(self, items, style):
        """Stile göre filtrele"""
        style_mapping = {
            'casual': ['tShirt', 'jeans', 'shorts', 'shoes', 'jacket', 'accessory', 'hat'],
            'formal': ['shirt', 'blouse', 'pants', 'skirt', 'dress', 'shoes', 'boots', 'coat', 'accessory'],
            'sporty': ['tShirt', 'shorts', 'shoes', 'jacket', 'hat', 'accessory']
        }
        
        suitable_types = style_mapping.get(style, [])
        return [item for item in items if item['type'] in suitable_types]
    
    def _needs_outerwear(self, weather):
        """Dış giyim gerekiyor mu?"""
        temperature = weather['temperature']
        condition = weather['condition'].lower()
        
        return temperature < 15 or any(c in condition for c in ['rain', 'snow', 'storm'])
    
    # Kategori kontrol fonksiyonları
    def _is_dress(self, item):
        return item['type'] == 'dress'
    
    def _is_top(self, item):
        return item['type'] in ['tShirt', 'shirt', 'blouse', 'sweater']
    
    def _is_bottom(self, item):
        return item['type'] in ['jeans', 'pants', 'shorts', 'skirt']
    
    def _is_shoes(self, item):
        return item['type'] in ['shoes', 'boots']
    
    def _is_outerwear(self, item):
        return item['type'] in ['jacket', 'coat']
    
    def _is_accessory(self, item):
        return item['type'] in ['accessory', 'hat', 'scarf', 'other'] 