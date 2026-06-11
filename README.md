# Boundary Shield - iOS Dijital Disiplin Uygulaması

Boundary Shield, kullanıcının belirlediği dijital sınırları aşmasını engelleyen, motivasyon serileri ve disiplin sistemiyle donatılmış, %100 native ve yerel (local-only) çalışan bir iOS uygulamasıdır.

Bu proje, **macOS/Xcode bağımlılığı olmadan kalıcı olarak bir Windows bilgisayar üzerinde geliştirilebilecek** şekilde yeniden yapılandırılmıştır. Kod geliştirme, sürüm kontrolü ve planlama Windows üzerinde yapılırken; derleme, birim testleri ve IPA paketleme işlemleri bulut tabanlı bir macOS ortamında (GitHub Actions) otomatik olarak gerçekleştirilir.

---

## 1. Proje ve Target Yapısı

Proje, macOS bulut ortamına aktarıldığında tek komutla Xcode projesi üretebilmesi için **XcodeGen** ile yapılandırılmıştır. `project.yml` dosyası, tüm hedef yapılandırmalarını barındırır.

### Target Listesi
1. **`BoundaryShield`**: Ana SwiftUI uygulaması. Arayüz ekranları, onboarding, profil ve ayarları barındırır.
2. **`BoundaryShieldDeviceActivityMonitor`**: Günlük süre limit aşımlarını izleyen arka plan servis extension'ı.
3. **`BoundaryShieldShieldConfiguration`**: Limit dolduğunda tetiklenen kilit ekranını (shield) özelleştiren extension.
4. **`BoundaryShieldShieldAction`**: Kilit ekranı üzerindeki eylemleri yakalayan ve bypass engeli uygulayan extension.
5. **`BoundaryShieldTests`**: Core mantık birim testlerini içeren XCTest target'ı.

### Dizin Yapısı
* `BoundaryShield/Sources/Core/`: Veri modelleri, thread-safe AppGroup veri deposu (`AppGroupStore`), reset yöneticisi (`SafeDailyResetManager`), yetkilendirme ve disiplin/ihlal motorları (`DisciplineEngine`).
* `BoundaryShield/Sources/UI/`: SwiftUI tabanlı modern, minimalist obsidian/bakır renk şemalı ekran tasarımları.
* `BoundaryShield/Sources/Extensions/`: Screen Time uzantı kodları (`DeviceActivityMonitorExtension`, `ShieldConfigurationExtension`, `ShieldActionExtension`).
* `BoundaryShield/Sources/Resources/`: Entitlements, Info.plist ve yerelleştirme (Localization) dosyaları.
* `BoundaryShield/Tests/`: Birim testleri (`XCTestCase`).

---

## 2. Windows Geliştirme Akışı (Windows Development Workflow)

Windows üzerinde tamamen Mac/Xcode açmadan geliştirme döngüsü şu adımlardan oluşur:

```
  [ Windows Bilgisayar ]                   [ GitHub Actions (Cloud macOS) ]
+-------------------------+               +--------------------------------+
|  1. Kodu Düzenle        |  Git Push     |  3. xcodegen generate          |
|  2. Git Commit yap      |-------------->|  4. xcodebuild test (Simulator)|
|                         |               |  5. xcodebuild archive         |
|  7. Hataları Düzelt     |<--------------|  6. IPA İhraç & Artifact Yükle |
+-------------------------+  İndir & Kur  +--------------------------------+
             ^                                            |
             |                                            | BoundaryShield.ipa
             +------------------[ USB / Sideload ]--------+
                                 iPhone Cihazı
```

1. **Kod Geliştirme**: Windows üzerinde tercih ettiğiniz kod editörü (VS Code, Cursor vb.) ile Swift ve SwiftUI kodlarını düzenleyin.
2. **Değişiklikleri Kaydetme**: Yapılan değişiklikleri standart git komutlarıyla yerel depoya commit edin.
3. **Buluta Gönderme**: Kodları GitHub uzak deposuna push edin. Push işlemi otomatik olarak GitHub Actions build workflow'unu tetikler.
4. **Build & Test**: GitHub Actions (macOS Runner) üzerinde proje XcodeGen ile derlenir, birim testler koşturulur ve IPA paketi hazırlanır.
5. **IPA İndirme**: Başarılı derleme sonrasında oluşturulan IPA dosyasını GitHub Actions Artifacts bölümünden Windows bilgisayarınıza indirin.
6. **Cihaza Kurulum**: İndirilen IPA dosyasını bir USB kablosu aracılığıyla Windows bilgisayarınızdan iPhone'unuza sideload edin (Ayrıntılar Bölüm 4'tedir).

---

## 3. GitHub Actions Build Workflow

Bulut tabanlı derleme sistemi `.github/workflows/ios-build.yml` dosyası altında tanımlanmıştır. 

### Workflow Adımları:
* **macOS Runner (Apple Silicon)**: En hızlı derleme süreleri için Apple Silicon tabanlı `macos-14` runner'ı kullanılır.
* **Xcode Kurulumu**: Derleme için kararlı `Xcode 15.4` sürümü seçilir.
* **XcodeGen Generate**: Proje kök dizinindeki `project.yml` okunarak `BoundaryShield.xcodeproj` ve ilişkili tüm Xcode target'ları, entitlements ve Info.plist dosyaları sıfırdan oluşturulur.
* **Birim Testleri (xcodebuild test)**: `BoundaryShieldTests` şeması iOS Simülatöründe (`iPhone 15, OS 17.5`) çalıştırılır.
* **Xcode Archive**: Uygulama Release (veya signing yoksa Debug) modunda derlenerek `.xcarchive` paketi üretilir.
* **Export IPA**: 
  * **İmzalı (Signing Konfigüre Edilmiş)**: Apple Developer sertifikaları ve provisioning profilleri kullanılarak cihazda çalışabilir gerçek bir IPA üretilir.
  * **İmzasız (Generic/Simulator)**: Geliştirici sertifikaları girilmemişse, workflow hata vermeden imzasız `.app` dosyasını `Payload/` klasörüne alıp zip'leyerek test amaçlı bir imzasız IPA taklidi üretir.
* **Upload Artifact**: Üretilen IPA dosyası, GitHub Actions arayüzünden indirilebilecek şekilde artifact olarak kaydedilir.

---

## 4. Windows + iPhone Test Workflow (IPA Yükleme)

Üretilen IPA dosyasını Windows bilgisayarınız üzerinden iPhone cihazınıza kurmak için aşağıdaki sideloading yöntemlerinden birini kullanabilirsiniz.

### Yöntem A: Sideloadly (Önerilen)
Sideloadly, Windows üzerinde çalışan ve Apple kimliğinizi kullanarak IPA dosyalarını cihazınıza imzalayıp kurabilen ücretsiz bir CLI/GUI aracıdır.

1. **Sideloadly Kurulumu**: [sideloadly.io](https://sideloadly.io/) adresinden Windows sürümünü indirin ve kurun.
2. **iTunes & iCloud**: Windows bilgisayarınızda Apple'ın resmi iTunes ve iCloud uygulamalarının (Microsoft Store sürümü olmayan, doğrudan Apple sitesinden indirilen standart masaüstü sürümleri) kurulu olduğundan emin olun.
3. **Bağlantı**: iPhone'unuzu USB kablosuyla bilgisayara bağlayın ve telefonda çıkan ekranda "Bu Bilgisayara Güven" seçeneğini onaylayın.
4. **Yükleme**:
   - Sideloadly programını açın.
   - İndirdiğiniz `BoundaryShield.ipa` dosyasını sürükleyip sol üstteki IPA kutusuna bırakın.
   - **Apple account** kısmına Apple kimliğinizi (e-posta) girin.
   - **Start** butonuna tıklayın, istendiğinde Apple kimliği şifrenizi girin.
   - Yükleme işlemi tamamlandığında cihazınızda uygulama görünecektir.
5. **Geliştirici Modu & Güven**:
   - Telefonunuzda **Ayarlar > Genel > VPN ve Cihaz Yönetimi** menüsüne gidin.
   - Apple kimliğinizin altında listelenen geliştirici sertifikasına dokunun ve "Güven" seçeneğini seçin.
   - iOS 16+ cihazlar için **Ayarlar > Gizlilik ve Güvenlik > Geliştirici Modu** seçeneğini aktif edip cihazı yeniden başlatın.

### Yöntem B: AltStore / AltServer
AltStore, bilgisayarınızda bir arka plan servisi (AltServer) çalıştırarak telefonunuza kablosuz veya kablolu olarak uygulama yüklemenizi ve 7 günde bir otomatik yenilenmesini sağlar.

1. Windows bilgisayarınıza **AltServer** programını kurun.
2. iPhone'unuzu USB ile bağlayıp bilgisayarınız üzerinden "Install AltStore" seçeneğiyle telefona AltStore uygulamasını yükleyin.
3. İndirdiğiniz `BoundaryShield.ipa` dosyasını iPhone'unuzda açıp AltStore uygulamasıyla "Open In..." seçeneğini kullanarak telefondan doğrudan kurun.

---

## 5. IPA Üretimi İçin Signing & Secrets Kurulumu

Eğer Apple Developer programına üyeyseniz ve uygulamanın Screen Time (Family Controls) yetkilerini gerçek cihazda tam olarak test etmek istiyorsanız, uygulamanın resmi bir sertifikayla imzalanması gerekir. Bunun için GitHub reponuzun **Settings > Secrets and variables > Actions** menüsünden aşağıdaki secrets tanımlamalarını yapmalısınız.

### GitHub Secrets Tablosu

| Secret İsmi | Açıklama | Değeri Nasıl Alınır? |
| :--- | :--- | :--- |
| `APPLE_TEAM_ID` | Apple Developer hesabınıza ait 10 haneli Team ID. | Developer portalından (Membership Details) alınır. |
| `IOS_CERTIFICATE_P12_BASE64` | Apple Development veya Distribution sertifikanızın (.p12) Base64 formatında kodlanmış hali. | Keychain Access'ten `.p12` olarak ihraç edin ve terminalde base64'e çevirin. |
| `IOS_CERTIFICATE_PASSWORD` | `.p12` sertifika dosyasını ihraç ederken belirlediğiniz şifre. | Sertifikayı oluştururken girdiğiniz parola. |
| `IOS_PROVISIONING_PROFILE_BASE64` | Uygulama ve tüm extension'lar için oluşturulmuş Provisioning Profile dosyasının (.mobileprovision) Base64 formatında kodlanmış hali. | Developer portalından indirdiğiniz `.mobileprovision` dosyasını terminalde base64'e çevirin. |
| `KEYCHAIN_PASSWORD` | Bulut macos makinesinde geçici keychain oluşturmak için kullanılacak rastgele güçlü bir şifre. | Kendiniz belirleyebilirsiniz (Örn: `Sifre123!`). |

> [!TIP]
> **Base64 Dönüştürme Komutu (Windows PowerShell)**:
> ```powershell
> [Convert]::ToBase64String([IO.File]::ReadAllBytes("sertifika.p12")) | Out-File -FilePath certificate_base64.txt
> ```
> Oluşan `.txt` dosyasındaki tek satırlık uzun metni kopyalayıp GitHub Secret alanına yapıştırın.

---

## 6. Screen Time & Family Controls Entitlement Notları

Apple, Screen Time API yeteneklerini (Family Controls) varsayılan olarak her geliştiriciye açık tutmaz. 

* **Apple Geliştirici Hesabı Şartı**: Family Controls API'sini kullanabilmek için ücretli bir Apple Geliştirici Hesabı gereklidir. Ücretsiz kişisel hesaplar bu yetkiyi derleyemez.
* **Yetki Başvurusu**: Apple Developer Portal üzerinden **Family Controls Entitlement** başvurusu yapılmalı ve onay alınmalıdır.
* **App Group Tanımı**: Ana uygulama ve tüm uzantıların (extensions) aynı App Group (`group.com.asujai.boundaryshield`) altında yer alması gerekir. Bu değer `AppConfiguration.swift` dosyasında merkezi olarak tanımlanmıştır:
  ```swift
  public enum AppConfiguration {
      public static let appGroup = "group.com.asujai.boundaryshield"
      public static let monitorExtensionBundleId = "com.asujai.boundaryshield.deviceactivitymonitor"
  }
  ```
* Bu grup tanımlamaları hem `project.yml` içindeki target ayarlarında hem de her target'ın `.entitlements` dosyasında birebir eşleşmelidir.

---

## 7. Gerçek Cihaz Test Kontrol Listesi (Checklist)

Windows üzerinden yükleme yaptıktan sonra gerçek cihazda şu adımlarla doğrulama gerçekleştirilmelidir:

- [ ] **Aile Paylaşımı / Ekran Süresi İzni**: Uygulama ilk açıldığında `AuthorizationCenter.shared.requestAuthorization` tetiklenip "Ekran Süresi İzni" onay penceresi geliyor mu?
- [ ] **Uygulama Seçici Ekranı**: Kural eklerken `FamilyActivityPicker` açılıyor mu ve kısıtlamak istediğiniz uygulamaları seçebiliyor musunuz?
- [ ] **Süre Limiti Aşımı**: Seçilen bir uygulamaya 1 dakikalık bir test kısıtlaması koyun. Süre dolduğunda ekran başarıyla kararıyor mu (Shield)?
- [ ] **Bypass Girişimi Engeli**: Shield ekranı çıktığında kilit ekranındaki "Tamam" veya eylem butonlarına dokunulduğunda kilit açılmadan kalıyor mu?
- [ ] **Tarih Değiştirme Koruması**: Cihaz saatini 2 saat ileri veya 1 gün geri alıp kilitleri aşmayı deneyin. Güvenli günlük reset yöneticisi bypass girişimini tespit edip korumayı sürdürüyor mu?
- [ ] **Seviye & Rozet Durumu**: Limit aşıldığında ve disiplin ihlali gerçekleştiğinde `DisciplineEngine` bunu kaydedip kullanıcı seviyesini sıfırlıyor veya kırmızı rozet ataması yapıyor mu?
- [ ] **Uygulama Silme Kilidi**: Uygulamayı silme veya sınır kuralını kaldırma eyleminde 5 saniye basılı tutma zorunluluğu doğru çalışıyor mu?
- [ ] **Tüm Verileri Sıfırlama**: Ayarlar menüsünden "Tüm Verileri Temizle" dendiğinde tüm kısıtlamalar kalkıyor ve yerel veri deposu sıfırlanıyor mu?

---

## 8. Bilinen Sınırlamalar (Limitations)

* **Yerel Simülatör Yok**: Windows makinede yerel olarak macOS işletim sistemi ve Xcode Simülatörü çalıştırılamaz. Tüm UI testleri veya derleme kontrolleri cloud macOS çıktısı IPA ile gerçek cihazda veya uzaktan yapılmalıdır.
* **Screen Time API Simülatör Kısıtları**: Apple'ın Family Controls API'si iOS simülatöründe bazı durumlarda (özellikle shield gösterme ve arka plan monitorizasyonunda) stabil çalışmaz. Bu nedenle nihai testler mutlaka gerçek cihazda (iPhone) yapılmalıdır.
* **7 Günlük Sideloading Limiti**: Bireysel Apple Developer hesabı yerine ücretsiz Apple ID ile Sideloadly kullanarak kurulan uygulamalar, Apple güvenlik politikaları gereği 7 gün sonra açılmaz hale gelir. Bu durumda uygulamayı bilgisayardan tekrar sideload etmek gerekir.

---

## 9. Hata Ayıklama Adımları (Debugging)

Windows üzerinden cihazdaki logları okumak ve hata ayıklamak için şu adımları izleyin:

1. **3uTools ile Canlı Log Takibi**:
   - 3uTools programını Windows bilgisayarınıza kurun ve iPhone'u bağlayın.
   - **Toolbox > Real-Time Log** menüsüne gidin.
   - Arama kutusuna `BoundaryShield` yazarak uygulamanızın veya extension'larının yazdığı `print` loglarını ve hata mesajlarını canlı olarak izleyin.
2. **Crash Logları**:
   - Telefonunuzda **Ayarlar > Gizlilik ve Güvenlik > Analizler ve İyileştirmeler > Analiz Verileri** menüsüne gidin.
   - Listeden `BoundaryShield` ile başlayan dosyaları bulup içeriğini inceleyin veya bilgisayara aktarın.
