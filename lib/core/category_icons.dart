import 'package:flutter/material.dart';

class CategoryIcons {
  // アイコン名からIconDataへのマッピング
  static IconData getIcon(String iconName) {
    if (iconName.isEmpty) return Icons.category_rounded;
    
    final iconMap = {
      // 支出カテゴリ
      'food': Icons.restaurant_menu_rounded,
      'shopping': Icons.shopping_bag_rounded,
      'transport': Icons.directions_car_rounded,
      'home': Icons.home_rounded,
      'health': Icons.favorite_rounded,
      'entertainment': Icons.movie_rounded,
      'education': Icons.school_rounded,
      'utilities': Icons.lightbulb_rounded,
      'phone': Icons.phone_android_rounded,
      'insurance': Icons.shield_rounded,
      'gift': Icons.card_giftcard_rounded,
      'pet': Icons.pets_rounded,
      'beauty': Icons.face_rounded,
      'sports': Icons.fitness_center_rounded,
      'travel': Icons.flight_rounded,
      'cafe': Icons.local_cafe_rounded,
      'grocery': Icons.local_grocery_store_rounded,
      
      // 収入カテゴリ
      'salary': Icons.account_balance_wallet_rounded,
      'bonus': Icons.stars_rounded,
      'investment': Icons.trending_up_rounded,
      'gift_income': Icons.redeem_rounded,
      'freelance': Icons.work_rounded,
      'business': Icons.business_center_rounded,
      'other_income': Icons.attach_money_rounded,
      
      // デフォルト
      'default': Icons.category_rounded,
    };
    
    return iconMap[iconName.toLowerCase()] ?? Icons.category_rounded;
  }

  // カテゴリ名からアイコンを推測
  static IconData guessIcon(String categoryName, String type) {
    final name = categoryName.toLowerCase();
    
    if (type == 'expense') {
      if (name.contains('食') || name.contains('飲') || name.contains('レストラン')) {
        return Icons.restaurant_menu_rounded;
      } else if (name.contains('買') || name.contains('ショッピング')) {
        return Icons.shopping_bag_rounded;
      } else if (name.contains('交通') || name.contains('車') || name.contains('電車')) {
        return Icons.directions_car_rounded;
      } else if (name.contains('家') || name.contains('住')) {
        return Icons.home_rounded;
      } else if (name.contains('医療') || name.contains('健康') || name.contains('病院')) {
        return Icons.favorite_rounded;
      } else if (name.contains('娯楽') || name.contains('映画') || name.contains('ゲーム')) {
        return Icons.movie_rounded;
      } else if (name.contains('教育') || name.contains('学')) {
        return Icons.school_rounded;
      } else if (name.contains('光熱') || name.contains('電気') || name.contains('ガス')) {
        return Icons.lightbulb_rounded;
      } else if (name.contains('通信') || name.contains('携帯') || name.contains('スマホ')) {
        return Icons.phone_android_rounded;
      } else if (name.contains('保険')) {
        return Icons.shield_rounded;
      } else if (name.contains('カフェ') || name.contains('コーヒー')) {
        return Icons.local_cafe_rounded;
      } else if (name.contains('スーパー') || name.contains('食料品')) {
        return Icons.local_grocery_store_rounded;
      }
    } else if (type == 'income') {
      if (name.contains('給料') || name.contains('給与') || name.contains('サラリー')) {
        return Icons.account_balance_wallet_rounded;
      } else if (name.contains('ボーナス') || name.contains('賞与')) {
        return Icons.stars_rounded;
      } else if (name.contains('投資') || name.contains('配当')) {
        return Icons.trending_up_rounded;
      } else if (name.contains('副業') || name.contains('フリーランス')) {
        return Icons.work_rounded;
      } else if (name.contains('事業') || name.contains('ビジネス')) {
        return Icons.business_center_rounded;
      }
    }
    
    return Icons.category_rounded;
  }

  // デフォルトカテゴリの定義
  static List<Map<String, String>> getDefaultCategories() {
    return [
      // 支出カテゴリ
      {'name': '食費', 'type': 'expense', 'color': '#FF6B6B', 'icon': 'food'},
      {'name': '買い物', 'type': 'expense', 'color': '#4ECDC4', 'icon': 'shopping'},
      {'name': '交通費', 'type': 'expense', 'color': '#45B7D1', 'icon': 'transport'},
      {'name': '住居費', 'type': 'expense', 'color': '#96CEB4', 'icon': 'home'},
      {'name': '医療費', 'type': 'expense', 'color': '#FF8B94', 'icon': 'health'},
      {'name': '娯楽', 'type': 'expense', 'color': '#DDA15E', 'icon': 'entertainment'},
      {'name': '教育', 'type': 'expense', 'color': '#BC6C25', 'icon': 'education'},
      {'name': '光熱費', 'type': 'expense', 'color': '#FFDAB9', 'icon': 'utilities'},
      {'name': '通信費', 'type': 'expense', 'color': '#87CEEB', 'icon': 'phone'},
      {'name': 'カフェ', 'type': 'expense', 'color': '#D4A574', 'icon': 'cafe'},
      
      // 収入カテゴリ
      {'name': '給料', 'type': 'income', 'color': '#66BB6A', 'icon': 'salary'},
      {'name': 'ボーナス', 'type': 'income', 'color': '#FFD700', 'icon': 'bonus'},
      {'name': '投資', 'type': 'income', 'color': '#9C27B0', 'icon': 'investment'},
      {'name': '副業', 'type': 'income', 'color': '#42A5F5', 'icon': 'freelance'},
      {'name': 'その他収入', 'type': 'income', 'color': '#26A69A', 'icon': 'other_income'},
    ];
  }
}
