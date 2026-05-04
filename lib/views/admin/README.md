# Admin Dashboard Screen

Admin dashboard yang **hanya mengambil warna dan style dari Figma**, tanpa struktur kompleks.

## 🎨 Yang Diambil dari Figma:

✅ **Warna** - Sahara theme (warm beige, orange accent)  
✅ **Font** - EB Garamond & Manrope  
✅ **Style** - Border radius, shadows, spacing  

❌ **TIDAK** ada bottom navbar  
❌ **TIDAK** ada struktur kompleks  

## 🚀 Cara Pakai:

```dart
import 'package:nyeni_app/views/admin/admin_dashboard_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AdminDashboardScreen(),
  ),
);
```

## 🎨 Warna:

```dart
Background:     #FAF5EE  // Warm beige
Accent:         #9A3412  // Sahara orange
Primary Text:   #3A302A  // Dark brown
Secondary Text: #78706A  // Light brown
```

## 📝 Features:

- Summary cards (4 cards dalam grid 2x2)
- Menu list (4 menu items)
- Simple & clean

## 🔧 Customize:

Ganti warna di file `admin_dashboard_screen.dart`:
```dart
const Color(0xFFFAF5EE) → const Color(0xYOUR_COLOR)
```

---

**Simple, clean, dan tetap cantik!** 🎉
