# SHOPIK — Native Flutter Customer Application

تطبيق Flutter أصلي متكامل ومستقل لخدمات شبيك (SHOPIK).

## المصدر والتصميم
واجهة التطبيق مبنية بصريًا بأحدث معايير Material 3: اتجاه RTL كامل، خط Cairo، ألوان شركات الاتصالات اليمنية، البطاقات، التبويبات، شبكة السداد، المتجر، العمليات، الحساب والوايفاي.

## Backend
العنوان الأساسي:
`https://shopik.alattab.site/api`

العقود المستخدمة في هذه النسخة:
- `POST /auth/login/` مع `{identifier,password}`
- `GET /auth/me/`
- `GET /wallets/`
- `GET /v2/services/catalog/`
- `GET /v2/services/services/{id}/`
- `POST /v2/services/requests/`
- `GET /v2/services/requests/{uuid}/`
- `GET /v2/services/requests/{uuid}/provider-check/`
- `GET /v2/services/reports/`
- `GET /v2/services/wifi/networks/`
- `POST /v2/services/wifi/purchase/` مع `amount`
- `GET /v2/services/wifi/my-cards/`
- `GET /home/`
- `GET /cities/`, `/categories/`, `/products/`, `/vendors/`
- `GET/POST/PATCH/DELETE /addresses/`
- `GET /orders/`
- `POST /orders/`
- `GET /orders/{id}/order_view/`
- `POST /orders/{id}/confirm_received/`
- `GET /notifications/`
- `POST /gifts/lookup/`
- `GET /gifts/`
- `POST /gifts/`
- `POST /gifts/{id}/confirm/`
- `POST /gifts/{id}/cancel/`

العمليات المدفوعة ترسل `Idempotency-Key`، ويتم حفظ الرمز المميز في `flutter_secure_storage`.

## إعدادات الأندرويد والتوقيع (Android & Signing)
- **اسم التطبيق**: شبيك باي (`android:label="شبيك باي"`)
- **حزمة التطبيق (Package Name / ApplicationId)**: `com.shopik.pay` (تم فصلها لمنع أي تعارض مع أي نسخة سابقة)
- **الأيقونات الرسمية**: أيقونة ذهبية وعنابية ملكية عصرية مُولدة لجميع مقاسات كثافة الشاشة `mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi` و `assets/icon/app_icon.png`
- **مفتاح التوقيع الرقمي**: `shopik_flutter/android/app/shopik-release.jks` (توقيع رقمي جديد منفصل صالح لـ 10000 يوم)
- **ملف التوقيع**: `shopik_flutter/android/key.properties` (كلمة المرور: `shopik_pay_secure_2026`, alias: `shopikpay`)

## التشغيل محليًا
```bash
cd shopik_flutter
flutter pub get
flutter run
```

## بناء حزم الإنتاج الموقعة (Release APK & AAB)
```bash
cd shopik_flutter
flutter pub get

# بناء ملف التثبيت APK
flutter build apk --release

# بناء حزمة متجر جوجل بلاي AAB
flutter build appbundle --release
```

المخرجات:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## البناء التلقائي عند الرفع إلى GitHub (GitHub Actions CI/CD)
تم إعداد ملفات سير العمل داخل المستودع:
- `.github/workflows/build-flutter.yml`
- `.github/workflows/build-flutter-native.yml`

بمجرد رفع الكود إلى GitHub (`git push`):
1. يبدأ الـ Workflow تلقائيًا بتهيئة بيئة Ubuntu مع Java 17 وأحدث إصدار Flutter Stable.
2. يتم فحص الكود والتأكد من اعتماداته.
3. يتم بناء كل من **APK** و **AAB**.
4. تتوفر الملفات مباشرة للتحميل كـ Artifacts في صفحة الـ Actions في المستودع.
