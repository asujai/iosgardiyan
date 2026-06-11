# Boundary Shield - iOS Dijital Disiplin Uygulaması

Boundary Shield, kullanıcının belirlediği dijital sınırları aşmasını engelleyen, motivasyon serileri ve disiplin sistemiyle donatılmış, %100 native ve yerel bir iOS uygulamasıdır. 

Uygulama, üçüncü taraf SDK'lar veya internet erişimi kullanmaksızın, Apple'ın resmi **Screen Time (Aile Denetimleri)** API altyapısını kullanarak doğrudan işletim sistemi düzeyinde koruma sağlar.

---

## 1. Geliştirme Ortamı ve Mimari

Bu proje, **Windows** üzerinde kodlama yapılması ve **macOS / Xcode** üzerinde derlenmesi mantığıyla taşınabilir bir yapıda kurulmuştur.

### Klasör Yapısı
* `BoundaryShield/Sources/Core/`: Uygulama yapılandırmaları, veri deposu, bypass engelleme ve disiplin motorları.
* `BoundaryShield/Sources/UI/`: SwiftUI tabanlı modern, karanlık mod (obsidyen) ve bakır renk şemalı ekran tasarımları.
* `BoundaryShield/Sources/Extensions/`: iOS Screen Time Extension target kodları (Monitor, Shield Config, Shield Action).
* `BoundaryShield/Sources/Resources/`: Türkçe ve İngilizce dil destekleri.
* `BoundaryShield/Tests/`: Mimarinin iş mantığını test eden XCTest birim testleri.

---

## 2. Development on Windows (Windows Üzerinde Geliştirme)

> [!NOTE]
> Bu proje Windows bilgisayarda düzenlenebilir ve Git aracılığıyla yönetilebilir durumdadır. Ancak projenin derlenebilmesi ve test edilebilmesi için macOS gereklidir.

### Windows'ta Yapabilecekleriniz:
* Swift ve SwiftUI kaynak kodlarını düzenlemek ve genişletmek.
* Git versiyon kontrol işlemlerini yürütmek.
* Statik dosyaları ve yerelleştirme (localization) verilerini yönetmek.

### Windows'ta Yapamayacaklarınız (Mac/Xcode Gerektiren Noktalar):
* Xcode Simülatöründe çalıştırma ve arayüz testleri.
* iOS cihazına yükleme, provisioning profile ve signing (imzalama) işlemleri.
* Gerçek Screen Time API (FamilyActivityPicker) ve Shield Extension testleri.

---

## 3. macOS / Xcode Derleme ve Kurulum Adımları

Projenin macOS ortamına taşınmasından sonra derlenip çalıştırılması için şu adımlar izlenmelidir:

1. **Boş Proje Oluşturma**: Xcode'da `BoundaryShield` adında yeni bir SwiftUI projesi açın. Bundle ID olarak `com.asujai.boundaryshield` kullanın.
2. **Extension Target'ları Ekleme**: Projeye 3 adet yeni Target ekleyin:
   * **Device Activity Monitor Extension**: (Dosya ismi: `DeviceActivityMonitorExtension.swift`)
   * **Shield Configuration Extension**: (Dosya ismi: `ShieldConfigurationExtension.swift`)
   * **Shield Action Extension**: (Dosya ismi: `ShieldActionExtension.swift`)
3. **App Group Etkinleştirme**:
   * Ana uygulama ve her 3 extension için `Signing & Capabilities` sekmesinden `App Groups` entitlement'ını ekleyin.
   * Grup ismi olarak `group.com.asujai.boundaryshield` tanımlayın.
4. **Kod Dosyalarını Ekleme**: Windows'ta hazırlanan `Sources` altındaki kod dosyalarını Xcode projenize sürükleyip ilgili target referanslarını vererek dahil edin.
5. **İzin Bildirimleri (Info.plist)**: Ana uygulamanın `Info.plist` dosyasına Aile Kontrolü (`FamilyControls`) için izin açıklamalarını ekleyin.

---

## 4. iOS ve Android Kısıt Farklılıkları

iOS işletim sisteminin yüksek güvenlik ve gizlilik politikaları nedeniyle, koruma uygulamaları Android'e kıyasla farklı çalışır:

| Özellik | Android Yaklaşımı | iOS Native Yaklaşımı (Boundary Shield) |
| :--- | :--- | :--- |
| **Uygulama Listeleme** | Tüm sistem uygulamaları okunabilir. | Güvenlik nedeniyle listelenemez. Bunun yerine sistemin resmi `FamilyActivityPicker` arayüzü tetiklenir. |
| **Ekran Kilitleme** | Diğer uygulamaların üzerine custom overlay çizilir. | Custom overlay yasaktır. Sistem düzeyinde resmi `ManagedSettingsStore` shield ekranı tetiklenir. |
| **Arka Plan Takibi** | Arka planda sınırsız çalışan servis kurulur. | Arka planda sürekli takip yasaktır. Takip, Apple'ın `DeviceActivity` servisine devredilir. |
| **Kolay Bypass** | Uygulama kapatılarak bypass edilebilir. | Kilit ekranı extension'ı (`ShieldActionDelegate`) ile bypass tamamen engellenir. |

---

## 5. Gerçek Cihaz Test Kontrol Listesi (Checklist)

Mac/Xcode ile cihazınıza yükledikten sonra aşağıdaki akışları sırayla test edin:

* `[ ]` **FamilyControls Yetkilendirmesi**: İlk açılışta Screen Time izni istendiğinde onaylanıyor mu? Reddedilirse açıklayıcı boş durum gösteriliyor mu?
* `[ ]` **FamilyActivityPicker Seçimi**: Yeni sınır eklerken uygulamalar başarıyla seçilebiliyor ve kaydediliyor mu?
* `[ ]` **DeviceActivity İzleme**: Belirlenen süre sınırı boyunca arkaplanda izleme hatasız başlıyor mu?
* `[ ]` **Limit Aşımı ve Shield**: Süre limiti dolduğunda kilit ekranı (Shield) anında devreye giriyor mu?
* `[ ]` **Motivasyon Sözü Gösterimi**: Shield ekranında günün sözü yazar ismiyle birlikte şık bir şekilde gösteriliyor mu?
* `[ ]` **Bypass Engelleme**: Shield ekranındaki "Tamam" veya "Ana Uygulamaya Dön" butonuna basıldığında kilit aşılıyor mu? (Aşılmaması, kilitli kalması gerekir).
* `[ ]` **Bypass Korumalı Kural Yönetimi**: Aynı gün limit artışı istendiğinde bunun yarına planlandığı doğrulanıyor mu? (Süre azaltımı hemen uygulanmalıdır).
* `[ ]` **5 Saniye Basılı Tutarak Silme**: Kural silme butonu 5 saniye basılı tutulmadan silme işlemini engelliyor mu? Basılı tutarken ilerleme görselleştiriliyor mu?
* `[ ]` **Güvenli Günlük Reset**: Gece yarısından sonra ve en az 22 saat geçtiğinde limitler başarıyla sıfırlanıp yeni gün başarı/seri puanı veriliyor mu? (Saat geriye alınarak bypass yapılmaya çalışıldığında sıfırlamanın engellendiğini doğrulayın).
* `[ ]` **Tüm Verileri Temizleme**: Profil ekranından veriler temizlendiğinde tüm izlemeler durdurulup shield'lar kaldırılıyor mu?
