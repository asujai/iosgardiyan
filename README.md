# Boundary Shield - iOS Dijital Disiplin Uygulaması

Boundary Shield, kullanıcının belirlediği dijital sınırları aşmasını engelleyen, motivasyon serileri ve disiplin sistemiyle donatılmış, %100 native ve yerel (local-only) çalışan bir iOS uygulamasıdır.

Uygulama, üçüncü taraf SDK'lar veya herhangi bir sunucu bağlantısı olmaksızın, Apple'ın resmi **FamilyControls**, **DeviceActivity** ve **ManagedSettings** API altyapısını kullanarak doğrudan işletim sistemi düzeyinde koruma sağlar.

---

## 1. Proje ve Target Yapısı

Proje, macOS ortamına aktarıldığında tek komutla Xcode projesi üretilebilmesi için **XcodeGen** yapısı ile yapılandırılmıştır.

### Target Listesi
1. **`BoundaryShield`**: Ana SwiftUI uygulaması. Arayüz ekranları, onboarding, profil ve ayarları barındırır.
2. **`BoundaryShieldDeviceActivityMonitor`**: Günlük süre limit aşımlarını izleyen arka plan servis extension'ı.
3. **`BoundaryShieldShieldConfiguration`**: Limit dolduğunda tetiklenen kilit ekranını (shield) özelleştiren extension.
4. **`BoundaryShieldShieldAction`**: Kilit ekranı üzerindeki eylemleri yakalayan ve bypass engeli uygulayan extension.
5. **`BoundaryShieldTests`**: Core mantık birim testlerini içeren XCTest target'ı.

### Klasör Yapısı
* `BoundaryShield/Sources/Core/`: Veri modelleri, thread-safe AppGroup veri deposu, reset yöneticisi, yetkilendirme ve koruma motorları.
* `BoundaryShield/Sources/UI/`: SwiftUI tabanlı modern, obsidian/bakır renk şemalı ekran tasarımları.
* `BoundaryShield/Sources/Extensions/`: Screen Time uzantı kodları.
* `BoundaryShield/Sources/Resources/`: Entitlements, Info.plist ve yerelleştirme (Localization) dosyaları.
* `BoundaryShield/Tests/`: Birim testleri (`XCTestCase`).

---

## 2. Geliştirme ve Proje Üretme Rehberi

### Windows Ortamında Yapılabilecekler:
* Kod düzenleme ve yeni arayüzler geliştirme.
* Git versiyon kontrol işlemlerini yönetmek.
* Statik dosyaları ve `project.yml` dosyasını yapılandırmak.

### macOS Ortamında Xcode Projesi Üretme Adımları:
1. macOS cihazınıza **XcodeGen** kurun:
   ```bash
   brew install xcodegen
   ```
2. Proje dizinine giderek Xcode projesini üretin:
   ```bash
   xcodegen generate
   ```
3. Bu komut, dizindeki `project.yml` dosyasını okuyarak `BoundaryShield.xcodeproj` projesini tüm target'lar, entitlements referansları ve Info.plist yapılandırmalarıyla otomatik olarak oluşturacaktır.

### İmzalama ve Çalıştırma Notları:
* Hem ana uygulama hem de extension'lar `group.com.asujai.boundaryshield` App Group entitlements tanımına bağlıdır.
* Gerçek cihazda Screen Time yetkilerini test edebilmek için Apple Developer hesabına ait bir Provisioning Profile ile projeyi Xcode üzerinde imzalamanız gerekmektedir.

---

## 3. Güvenlik ve Bypass Engelleme Mekanizmaları

* **22 Saat Kuralı**: Cihaz saatinin manuel ileri alınarak serinin haksız yere artırılmasını veya sıfırlanmasını engeller.
* **Zaman Geriye Alma Tespiti**: Sistem uptime ve wall-clock takipleriyle saatin geriye alınarak limitlerin devre dışı bırakılmasını engeller.
* **Ertelenmiş Güncellemeler**: Süre limiti artışları ve aktif gün azaltma talepleri anında uygulanmaz, sonraki gün sıfırlanmasında (reset) devreye girer.
* **Korumalı Silme**: Sınır kuralının silinmesi için silme butonuna 5 saniye kesintisiz basılı tutulması gerekir.
* **Tavizsiz Kilit**: Shield Action Extension ile kilit ekranı buton eylemlerinde bypass engellenir ve kullanıcının kilit altındaki uygulamaya erişmesine izin verilmez.

---

## 4. Testleri Çalıştırma

macOS ortamında birim testleri koşturmak için:
* Xcode üzerinde `Cmd + U` kısayolunu kullanabilir veya terminalden aşağıdaki komutla test edebilirsiniz:
  ```bash
  xcodebuild test -project BoundaryShield.xcodeproj -scheme BoundaryShieldTests -destination 'platform=iOS Simulator,name=iPhone 15'
  ```

### Test Edilen Senaryolar:
1. `SafeDailyResetManagerTests`: 22 saat dolmadan reset yapılmaması, zaman geriye alındığında bypass korumasının devreye girmesi.
2. `DisciplineEngineTests`: İhlal durumunda seviye sıfırlanması, kırmızı rozet atanması ve 2 başarılı gün sonrasında telafi edilmesi.
3. `RuleEditingTests`: Limit artırımının yarına planlanması, limit azaltımının anında uygulanması.
4. `LocalDataStoreTests`: Verilerin atomik ve tutarlı bir şekilde UserDefaults'a yazılıp okunması.
5. `QuoteManagerTests`: Söz ekleme/silme ve random getirme doğrulamaları.

---

## 5. Gerçek Cihaz Test Kontrol Listesi (Checklist)

* `[ ]` **FamilyControls İzni**: İlk açılışta Screen Time yetkilendirmesi hatasız alınıyor mu?
* `[ ]` **Uygulama Seçimi**: `FamilyActivityPicker` üzerinden kısıtlanacak uygulamalar başarıyla seçilebiliyor mu?
* `[ ]` **Süre Sınırı Takibi**: Limit aşıldığında Device Activity Monitor arka planda kısıtlamayı tetikliyor mu?
* `[ ]` **Kilit Ekranı (Shield)**: Limit aşılınca kilit ekranı açılıyor ve motivasyon sözü gösteriliyor mu?
* `[ ]` **Kilit Eylemi (Bypass Engeli)**: Kilit ekranı üzerindeki eylem butonu bypass etmeden korumayı sürdürüyor mu?
* `[ ]` **Zaman Planlamaları**: Süre artışı yapıldığında yarına ertelenirken, süre azaltımı hemen uygulanıyor mu?
* `[ ]` **5s Buton Basılı Tutma**: Silme eyleminde 5 saniye basılı tutulması zorunlu kılınıyor mu?
* `[ ]` **Tüm Verileri Temizleme**: Sıfırlama yapıldığında tüm korumalar ve veriler temizleniyor mu?
