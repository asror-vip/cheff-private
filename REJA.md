# ChefControl AI — To‘liq biznes va texnik reja (Single Source of Truth / SRS)

> Holati: Loyihalash bosqichi — biznes qarorlari tasdiqlanishi kerak
Maqsad: Restoran, kafe va keyinchalik universal savdo nuqtalarida qog‘oz buyurtma, og‘zaki xabar va qo‘lda hisob-kitobni kamaytiradigan, xodimlar ishini sodda va ishonchli qiladigan POS/KDS/ERP tizimini yaratish.
Muhim qoida: bu hujjat reja va talablarni belgilaydi. Undagi biror texnik muammo koddan tekshirilmaguncha tasdiqlangan xato hisoblanmaydi. Ushbu hujjat egasi tasdiqlamagan xizmat haqi, soliq, to‘lov yoki biznes siyosatlarini kodda qat’iy belgilashga ruxsat bermaydi.

---

## 0. Mahsulot tamoyillari va ko‘lami
### 0.1. Asosiy maqsad
Xodim ilovada iloji boricha kam bosish bilan ishni bajarsin. Buyurtma bir marta kiritilsin va kerakli joylarga avtomatik uzatilsin. Harakatlar kim tomonidan, qachon va nima sababdan bajarilgani qayd etilsin.
### 0.2. Mahsulotning asosiy qismlari
- **Waiter Mobile:** ofitsiantning Android/iOS telefonidagi buyurtma va stol boshqaruvi.
- **Kitchen Display System (KDS):** oshpaz/barmen uchun planshet yoki katta ekran.
- **POS/Cashier:** kassir uchun kompyuter yoki katta planshetdagi savdo va to‘lov oynasi.
- **Inventory/Purchases/Production:** ombor, xarid, reviziya, brak, yarim tayyor mahsulot va batch ishlab chiqarish.
- **Management:** egasi/administrator uchun xodimlar, sozlamalar, analitika va hisobotlar.
- **Backend:** Supabase Auth, PostgreSQL, RLS, server-side RPC/Edge Functions, Realtime; fon vazifalari va tashqi integratsiyalar.
### 0.3. Dizayn qoidalari
1. Bitta asosiy biznes hodisasi bir marta qayd etiladi; takroriy so‘rov dublikat savdo/to‘lov/ombor harakati yaratmaydi.
2. Buyurtma holati, taom holati, stol holati, to‘lov holati va smena holati alohida boshqariladi.
3. Mobil interfeysda faqat ruxsat berilgan vazifalar ko‘rsatiladi, lekin haqiqiy xavfsizlik server tomonida ham tekshiriladi.
4. Realtime — ma’lumotning o‘zi emas, o‘zgarishni xabar qilish usuli. PostgreSQL’dagi tasdiqlangan holat asosiy manba bo‘lib qoladi.
5. Internet uzilganda foydalanuvchiga vaziyat ochiq ko‘rsatiladi; muvaffaqiyatli saqlanmagan ish bajarildi deb ko‘rsatilmaydi.
6. Fiskal chek va oddiy ichki chek bir xil tushuncha emas.
7. “AI” tekshiriladigan biznes qoidalarining o‘rnini bosmaydi: pul, ruxsat, ombor va chek bo‘yicha yakuniy qaror deterministik server kodida bajariladi.

---

## 1. Rollar, qurilmalar va ruxsatlar (RBAC/RLS)
Ruxsatlar tashkilot (`organization_id`) va filial (`branch_id`) doirasida tekshiriladi. Qurilma turi rolning o‘zi emas: bir xodim ruxsat berilgan qurilmalardan kirishi mumkin, biroq amallari roli bilan cheklanadi.

| Rol | Tavsiya etilgan qurilma | Ruxsat etilgan vazifalar | Taqiqlangan yoki alohida ruxsat talab qiladigan vazifalar |
| :--- | :--- | :--- | :--- |
| **Ofitsiant** | Android/iOS telefon | O‘ziga tayinlangan stollar, menyu, stop-list, mehmonlar soni, buyurtma qoralamasi, modifikator/izoh, oshxonaga yuborish, tayyor taomni topshirilgan deb belgilash, hisob so‘rash | Moliyaviy hisobot, xarid/ombor tahriri, to‘lovni yopish, yuborilgan taomni sabab/ruxsatsiz bekor qilish |
| **Oshpaz** | Devor plansheti/KDS | O‘z stansiyasining taomlari, cooking/ready holati, out-of-stock rad etish, retsept ko‘rish | To‘lov, narx, chek yopish, boshqa stansiya buyurtmalari, moliya |
| **Barmen** | Bar plansheti/KDS | Ichimlik stansiyasi, ichimlik tayyorlash holatlari | Boshqa stansiya va moliyaviy amallar |
| **Kassir** | POS / PC / Tablet | Faol stollar va pre-check, to‘lovlar, ruxsatga ko‘ra chegirma/bekor qilish, smena ochish/yopish, chek chiqarish | Ombor reviziyasi, xodim KPI/ish haqi, egasining hisobotlari |
| **Omborchi**| Telefon/planshet | Xarid talabnomasi, tovar qabul qilish, inventarizatsiya, ombor kirim/chiqim, spisaniya/brak, ishlab chiqarish | Kassa to‘lovi, xodim ish haqi, to‘liq P&L |
| **Admin** | Telefon/web/PC | Operatsion nazorat, stolni ofitsiantga o‘tkazish, ruxsat etilgan doirada xodimlar va ruxsatlarni boshqarish | Egasi bermagan moliyaviy amallar |
| **Egasi** | Telefon/web/PC | Tashkilot sozlamalari, filiallar, rollar, barcha hisobotlar, moliya, audit, tariflar va integratsiyalar | Qonun tomonidan cheklangan amallar |

### 1.1. Server-side xavfsizlik talablari
- Barcha biznes jadvallarida `organization_id` va `branch_id` bo'lishi shart.
- Muhim amallar (yuborish, bekor qilish, to'lov, ombor) faqat server-side tranzaksiyalar (RPC) orqali bajariladi.
- `service_role` mobil ilovada ishlatilmaydi.
- Kassir PIN-kodi xodimga bog‘langan va audit qilinadigan mexanizm bo'lishi kerak.

---

## 2. Restoranning kundalik ish jarayoni (Zanjir)

### 2.1. Smena boshlanishi
1. Kassir smenani ochadi va boshlang‘ich naqd pulni kiritadi.
2. Oshxona stop-listlarni kiritib, ishlashga tayyorligini belgilaydi.
### 2.2. Stol va mehmonlar
1. Ofitsiant bo‘sh stolni tanlaydi, mehmonlar sonini kiritadi. Stol mas'ul ofitsiantga biriktiriladi (`assigned_waiter_id`).
### 2.3. Buyurtmani tayyorlash va yuborish
1. Ofitsiant taomlarni savatga kiritadi (`draft` holatda qoladi). Izohlar yozishi mumkin.
2. "Oshxonaga yuborish" faqat *yangi draft* elementlarni yuboradi. Eski elementlar takror yuborilmaydi.
### 2.4. Oshxona va stansiyalar
1. Taomlar retseptdagi `station` bo'yicha tegishli KDS ekraniga tushadi. Oshpaz `cooking` qiladi, so'ng `ready` qiladi.
2. `ready` bo'lgach, faqat mas'ul ofitsiantga xabar yuboriladi. Ofitsiant `served` (tortildi) deb belgilaydi.
### 2.5. Hisob va to‘lov
1. Mijoz hisob so'raganda "Pre-check" chiqariladi.
2. Kassir hisobni ko'rib, Naqd/Karta/Aralash to'lov orqali yopadi. Chek yakunlanishi dublikat bo'lmasligi kerak.
### 2.6. Stolni bo‘shatish
1. To'lov yopilganda stol avtomat `cleaning` ga o'tadi, xodim tozalangach `available` bo'ladi.
### 2.7. Smenani yopish
1. Kassir tushumlarni ko'rib, farq bo'lsa sababini kiritib Z-otchyot yopadi.

---

## 3. Mustaqil holatlar (State machines)

### 3.1. Stol (restaurant_tables)
`available` (bo'sh) $\rightarrow$ `occupied` (faol buyurtma) $\rightarrow$ `bill_requested` (hisob so'ralgan) $\rightarrow$ `cleaning` (tozalash) $\rightarrow$ `out_of_service`.
### 3.2. Buyurtma (orders)
`open` (faol) $\rightarrow$ `in_progress` (oshxonada) $\rightarrow$ `ready_for_payment` $\rightarrow$ `partially_paid` $\rightarrow$ `paid` $\rightarrow$ `cancelled`. `order_type`: `dine_in`, `takeaway`, `delivery`.
### 3.3. Buyurtma elementi (order_items)
`draft` (yuborilmagan) $\rightarrow$ `sent` (oshxonada) $\rightarrow$ `cooking` $\rightarrow$ `ready` $\rightarrow$ `served` $\rightarrow$ `cancelled` $\rightarrow$ `rejected` (out of stock).
### 3.4. To‘lov (payments)
Alohida jadval qilinadi. `pending`, `succeeded`, `failed`, `voided`, `refunded`. Split bill va Aralash to'lov mustaqil ishlaydi.
### 3.5. Ombor / Smena
Kassa smenasi: `open` $\rightarrow$ `closing` $\rightarrow$ `closed`. Ombor: rezerv va haqiqiy sarf ajratiladi.

---

## 4. Istisno holatlar, nazorat va anti-fraud
1. **Dozakaz:** Faqat yangi `draft` lar `sent` bo'ladi. Eski tayyorlangan ovqatlar o'zgarmaydi.
2. **Taom bekor qilish:** Ofitsiant faqat `draft` ni o'chira oladi. Yuborilgan taomni faqat admin/kassir sabab (va pin) bilan o'chiradi. Auditga yoziladi.
3. **Stol ko'chirish:** Atomar bajariladi, narx ikki marta hisoblanmaydi.
4. **Stop-list:** KDS da kiritilgan taom ofitsiant menyusida zudlik bilan bloklanadi.
5. **Rad etish:** Oshpazda taom xomashyosi tugasa `rejected` qiladi, ofitsiantga tezkor xabar keladi.

---

## 5. KDS — oshxona ekranlari va stansiyalar
- **Stansiyalar:** `hot_kitchen`, `cold_kitchen`, `grill`, `bar`, `dessert`, `none`. `none` to'g'ridan to'g'ri `ready` bo'ladi.
- **KDS Tarkibi:** Ovozli signal, Taymer, retsept izohlari, va yirik o'qiladigan shriftlar. Bitta taomni ham, butun buyurtmani ham tayyor qilish imkoniyati.

---

## 6. Bildirishnomalar va sinxronizatsiya
1. **Kimga boradi:** Faqat mas'ul ofitsiantga (`assigned_waiter_id`).
2. **Foreground:** Supabase Realtime orqali jonli yangilanadi.
3. **Background:** FCM orqali Push notification.
4. **Kafolat:** Push bormasa ham, ilova ochilganda `ready` taomlar ro'yxati bazadan olinib ko'rsatiladi. 2 daqiqadan so'ng admin/navbatchiga eskalatsiya qilish (zaxira).

---

## 7. Ombor, retsept va Food Cost
1. **A-la-carte (Buyurtmaga pishiriladigan):** Buyurtma `sent` bo'lganda *rezerv* qilinadi, to'lov yopilganda *sarf (chiqim)* qilinadi (yoki biznes qoidasiga qarab sarf nuqtasi tasdiqlanadi). Checkout payti ikki marta ayirilmasligi shart.
2. **Batch production (Zagotovka):** Osh damlash kabi. `Production` yopilganda xomashyolar sarf qilinadi va +50 porsiya Tayyor osh kirim bo'ladi. Sotilganda esa xomashyo emas, 1 porsiya tayyor osh ayiriladi.
3. **Refund/Brak:** Qaytarilgan taom "Yaroqsiz/xodimlar ovqati" bo'lib PnL xarajatiga o'tadi, yana aylanmaga kirmaydi.

---

## 8. Internet, idempotency va parallel ishlash
1. **MVP (Ishonchli Online):** Tranzaksiyalarda `idempotency_key` qo'llanadi. Parallel ikki marta bosganda bitta operatsiya o'tadi. Net yo'qligida tugmalar bloklanib ogohlantirish beradi.
2. **Offline Mode:** Keyingi bosqichda ko'rib chiqiladi.

---

## 9. Mavjud kod bazasi auditi va bug backlog
Hozirgi yozilgan kodda quyidagi xatolar tekshirilib tuzatiladi:
1. `login_page.dart`: `switchToBoss()` sessiya xatolari.
2. `search_utils.dart` / UI: Kirill va unicode (Mojibake) xatolari.
3. `recipe_model.dart`: Category va description ustma-ust tushishi.
4. `ai_scanner_service.dart`: Model versiyasi va `created_at`/`date` ustun xatolari.
5. `sales_repository.dart`: Soxta `totalRev * 0.9` formulasini haqiqiy dataga almashtirish.
6. Mock Data'larni o'chirish va Excel eksportni ishlash.
7. RLS izolyatsiyasi.

---

## 10. Modullar o‘rtasidagi bog‘liqlik oqimi
Ofitsiant Mobile -> Stol/Order -> Idempotency -> KDS stansiyalari -> Taom statuslari -> Mas’ul ofitsiantga Realtime/FCM -> Taom topshirildi -> POS to‘lovi -> Savdo/Moliya ledgeri -> Ombor ledgeri -> Reports/Audit.

---

## 11. Qabul sinovlari (Acceptance Criteria)
1. **Yangi buyurtma:** Ofitsiant taom yuboradi -> 1 ta buyurtma yaratiladi, taom mos stansiyaga tushadi, stol band bo'ladi.
2. **Dozakaz:** Yangi choy urilsa -> KDS ga eski taom emas, faqat choy chiqadi.
3. **Ofitsiant xabari:** 5-stol Dilshodnikida, taom tayyor bo'lsa xabar faqat Dilshodga boradi.
4. **Push:** Push bormay qolsa, ofitsiant ilovani ochganda `ready` taomlarni baribir ko'radi.
5. **Anti-fraud:** Ofitsiant pishayotgan taomni o'chirolmaydi. Kassir sabab bilan o'chirganda Auditga tushadi.
6. **Batch Production:** 50 ta Osh qilingan. Sotilganda guruch ayirilmaydi, faqat Tayyor Osh ayiriladi.
7. **Aralash to'lov:** 100 ming naqd va 50 ming karta to'langanda summalar to'g'ri bo'linadi, bitta kassa tranzaksiyasiga yoziladi.
8. **Idempotency:** Net qotib 3 marta yuborsa ham bitta amal tushadi.

---

## 12. Bosqichlar va "Hal qilinishi kerak bo'lgan savollar"

### 12.1 MVP - Birinchi Navbatda (Kod hozirdan bunga tayyorlanadi)
Stolni mas'ulga biriktirish, menyu, dozakaz/idempotency, KDS stansiyalari, tayyor ro'yxat, kassada asosiy to'lov (naqd/karta), omborning 2 marta ayirmasligi, smena ochish/yopish auditi, xatolarni tuzatish.
### 12.2 2-bosqich va Kelajak
Split bill (Item level), Refund hujjatlari, Batch production chuqur hisobi, Z-otchyot murakkabligi, Offline mode.

### 💡 Hozir tasdiqlanishi kerak (Tasdiq kutayotgan savollar):
> Dasturchi ushbu qoidalar bo'yicha kod yozishni boshlashi uchun quyidagilar javobi aniq bo'lishi shart:

1. **Bir stolga bitta mas'ul:** Xabarlar va KPI aniqligi uchun 1 ta stolga faqat bitta mas'ul ofitsiant (`assigned_waiter_id`) biriktiramizmi?
2. **Xizmat haqi (`dine_in`):** Restoranda o'tirib yeganlarga 10% xizmat haqini qotirib qo'ymay, filial sozlamasi qilib berishga rozimisiz?
3. **Ombor sarf nuqtasi:** Kassa "To'lash"ni bosib chekni yopgan vaqtida (checkout) retsept bo'yicha mahsulotni ayirish sizning biznesingizga to'g'ri keladimi?
4. **Hisob so'ralgandan keyingi Dozakaz:** Mijozga Pre-chek chiqarilgach (Stol: `bill_requested`), u yana ovqat so'rasa ruxsat beramizmi yoki kassir blokni ochishi shartmi?
5. **Dozakaz/Tahrir qoidalari:** Yuborilgan taom ofitsiant tomonidan o'zgartirilmasligini (faqat o'zini qoralama `draft` savatidagini o'chirishi mumkinligini) joriy qilamizmi?
