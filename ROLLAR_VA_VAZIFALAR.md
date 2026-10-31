# ChefControl AI - Restoran Avtomatlashtirish Tizimidan Foydalanish Qoidalari (Biznes egalari uchun qo'llanma)

Hurmatli biznes egasi! Ushbu hujjat sizga va sizning xodimlaringizga **ChefControl AI** dasturi orqali restoraningizni qanday qilib o'g'riliksiz, zamonaviy va soatdek aniq ishlatish mumkinligini batafsil tushuntirib beradi. Tizim - bu faqat telefoningizdagi ilova emas. Bu — sizning restoraningizning yuragi!

---

## 🚀 TIZIM ISHLASHI UCHUN KERAK BO'LADIGAN TEXNIK MUHIT (APPARATLAR)
Dasturdan "Zo'r" darajada foyda ko'rish uchun sizning restoraningizda quyidagi texnik vositalar majburiy tartibda o'rnatilishi kerak:
1. **Tezkor va Uzluksiz Internet (Wi-Fi):** Kassa, ofitsiantlar va oshxona apparatlari aynan internet orqali bir-biri bilan sekundma-sekund (jonli) aloqada bo'ladi.
2. **Kassa uchun:** Bitta Katta Planshet yoki Kompyuter (Touch screen - sensor ekran) hamda Chek chiqarib beruvchi Bluetooth/USB Printer. Kassir shu apparat oldida doim o'tiradi.
3. **Oshxona (Oshpazlar) uchun:** Har bir muhim sexda (masalan, Issiq ovqatlar, Salatlar, Bar) devorga osilgan yoki stolda turadigan bittadan Planshet.
4. **Ofitsiantlar va Omborchi uchun:** Oddiy smartfon (telefon).

---

## 👥 XODIMLAR (ROLLAR) VA ULARNING ISH JARAYONI (QADAM-BAQADAM)

Dastur shunday aqlli qilinganki, unga ofitsiant o'z ID paroli bilan kirsa, u faqat "Stollar"ni ko'radi. Kassa yoki Omborni umuman ko'rmaydi. Bu o'g'rilik va adashishni 100% oldini oladi.

### 1️⃣ OFITSIANT (Mijoz bilan ishlash)
Ofitsiantlar qog'oz va ruchkani uloqtirib tashlashadi. Ularning yagona quroli - smartfon!
*   **1-qadam:** Mijoz keldi. Ofitsiant telefondan bo'sh stolni tanlaydi (ekranda bo'sh stollar ko'rinib turadi).
*   **2-qadam:** Mijoz so'ragan ovqatlarni (masalan: 2 ta Osh, 1 ta Choy) telefon ekranidan tanlab, **"Oshxonaga yuborish"** tugmasini bosadi. 
*   *(Shu zahoti Kassirning apparatida shu stolning hisobi paydo bo'ladi, oshxonadagi planshetda esa qizil rangda buyurtma ko'rinadi).*
*   **3-qadam:** Ofitsiant telefoniga qarab turadi. Boya o'zi yuborgan 2 ta Osh qizil (Kutmoqda) bo'lib turgan edi. Oshpaz uni pishirib bo'lgach, ofitsiantning ekranida u "Yashil" (Tayyor) degan rasmga aylanadi. U shu zahoti mijozga borib ovqatni beradi.

### 2️⃣ OSHPAZ VA OSHXONA SEXLARI (Kitchen KDS)
Oshpazlar endi chiyillab chiqadigan kassa apparatidan yirtib olingan qog'ozlarni o'qib o'tirishmaydi!
*   **1-qadam:** Oshpaz devordagi planshetga qarab turadi. Ofitsiant "Osh" buyurtma qilishi bilan, planshetda **QIZIL** rangli "1-stol: 2 ta Osh (Kutmoqda)" degan buyurtma paydo bo'ladi.
*   **2-qadam:** Oshpaz ovqatni boshlagach, o'sha qizil yozuv ustiga bitta bosadi va u **KO'K** rangga aylanadi (Tayyorlanmoqda).
*   **3-qadam:** Ovqat pishdi, tarelkalarga suzildi. Oshpaz ko'k yozuv ustiga bitta bosadi, u **YASHIL** rangga aylanib, ekrandan yo'qoladi. Tizim ofitsiantga xabar yuboradi.
*   **Zagatovka qadami (Bonus):** Oshpaz ertalab kelib qozonga 10 kg go'shtdan "Osh zagatovkasi" qilsa, uni ham shu planshetdan kiritib qo'yadi. Shunda ombordan srazi 10 kg go'sht yechiladi va hisobda adashmovchilik bo'lmaydi.

### 3️⃣ KASSIR VA KASSA SMENASI (Cashier)
Kassir restoranning "qulf-kaliti" hisoblanadi.
*   **1-qadam (Smenani ochish):** Ertalab kassir o'z akkauntiga kiradi. Tizim unga hech narsani ko'rsatmaydi! Unga **"Smenani och, hozir kassa yashigida qancha naqd pul bor?"** degan savol chiqadi. Kassir masalan "150,000 so'm" deb kiritib smenani ochadi.
*   **2-qadam (To'lov olish):** Mijoz ketayotganda, Kassir apparatdan o'sha stolni topadi (masalan, 3-stol 200,000 so'm bo'lgan). Mijoz 150,000 ni Naqd, 50,000 ni Karta orqali berdi. Kassir to'lovni "Aralash" qilib yopadi va Printerdan Chek qog'ozi chiqib keladi.
*   *Yashirin qadam:* Chek yopilgan soniyada ombordan taomlarga ishlatilgan (kalkulyatsiya qilingan) barcha mahsulotlar (masalan 2 ta osh uchun 300gr go'sht, 200gr guruch) avtomatik ravishda Ombordan yechib tashlanadi!
*   **3-qadam (Smenani yopish):** Kechqurun uyga ketayotganda kassir smenani yopishni bosadi. Tizim yana so'raydi: "Kassada hozir necha pul bor?". Kassir sanab "500,000 so'm bor" deb yozadi. Agar kassada aslida 550,000 so'm bo'lishi kerak bo'lgan bo'lsa, tizim darhol Xo'jayinga (Rahbarga) **"Kassirda 50,000 so'm NEDOSTACHA (Kamomad)"** deb xabar yuboradi.

### 4️⃣ OMBORCHI VA TA'MINOTCHI (Inventory & Cost)
Omborchi tizimning miyasi bilan ishlaydi.
*   **1-qadam:** Bozor qilib kelgach, u go'sht, piyoz va sabzilarni narxi va qancha olganligini tizimga kirim qiladi.
*   **2-qadam (Brak):** Agar 5 kg kartoshka aynib chirib qolsa, u "Chiqitga chiqarish (Waste)" degan tugma orqali uni rasman hisobdan yechadi.
*   **3-qadam (Reviziya):** Har oyning 1-sanasida Omborchi Rahbar bilan birga "Reviziya" oynasini ochadi. Tizim aytadi: "Go'sht omborda 10kg qolgan bo'lishi kerak". Ular go'shtni taroziga qo'yib ko'radi: 9.5 kg chiqdi. Tizimga "9.5 kg" deb kiritiladi. Tizim yarim kilo go'sht qayerdadir "yo'qolganini" hisobot qilib saqlab qoladi va qoldiqni real holatga to'g'irlaydi.

### 5️⃣ RAHBAR (Siz) VA SUN'IY INTELLEKT
Siz restoranda bo'lishingiz shart emas. Tizim to'liq sizning nazoratingizda!
*   **Hamma ma'lumot qolingizda:** Telefoningizdan ilovaga kirsangiz, siz "Kassada hozir qancha pul yig'ildi", "Qaysi xodimlar ishda o'tiribdi", "Omborda nimalar tugayapti" barchasini ko'rasiz.
*   **AI Yordamchi:** Tizimda "Sun'iy intellekt" mikrofoni bor. Unga ruscha yoki o'zbekcha "Bugun qaysi ovqat eng ko'p sotildi?" yoki "Kassir qancha savdo qildi?" deb ovozli savol bersangiz, kompyuter sizga hisob-kitobni o'qib beradi! Bu xuddi qo'l ostingizdagi shaxsiy buxgalterdek gap.

---

## 🛡 Nega tizim o'g'riliklarga yo'l qo'ymaydi?
1. Agar Ofitsiant ovqatni tizimga urmasa, Kassa uni pulini to'lay olmasligini tushunadi.
2. Agar ofitsiant tizimga ovqatni ursa, uni o'chirish huquqi unda bo'lmaydi, chunki Oshpazning ekraniga u ovqat allaqachon borganku (pishirmoqda).
3. Oshpaz qozonga qancha tashlagani muhim emas, Ombor baribir retsept bo'yicha (kalkulyatsiya) aniq yechib ketaveradi, keyin esa Reviziya payti 1 grammigacha o'g'rilik/ortiqchalik kelib chiqadi.
4. Kassir kassadagi pulni noto'g'ri sanasa yoki o'g'irlasa, smena yopilishida 1 so'migacha kamomad rahbarning telefoniga SMS/Xabar bo'lib boradi. 
5. Barcha "Zagatovka", "Brak qilingan mahsulot", "Kassa to'lovlari" maxsus loglarda saqlanadi, uni hech bir xodim (hatto admin ham) bittada o'chirib yubora olmaydi. 

Biz ushbu tizimni **Sizning xotirjamligingiz** va **Restoraningiz daromadi oshishi** uchun yaratdik!
