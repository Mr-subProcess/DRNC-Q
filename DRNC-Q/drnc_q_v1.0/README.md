# DRNC-Q v1.0 — bağımsız ilişkisel kuantum programlama dili

**DRNC-Q v1.0**, DRNC odaklı bir dil çekirdeğidir: kendi `.drq` kaynak sözdizimi, derleyicisi, doğrulayıcısı, `DRNQB3` bytecode kapsayıcısı, sanal makinesi, standart kütüphanesi ve yerel state-vector kuantum simülatörü vardır. Python, Qiskit, bulut hesabı veya sağlayıcı API'si çalışma bağımlılığı değildir.

Bu sürümün teslim kapsamı `LANGUAGE_SPEC.md` içinde tanımlıdır. Kapsam dışı özellikler (örneğin kalıtım, generics, closure veya fiziksel QPU pulse kontrolü) destekleniyormuş gibi gösterilmez.

## Hızlı başlangıç

Arşivi açtıktan sonra Linux x86-64 üzerinde:

```sh
./drnq --version
./drnq check examples/full_drncq_demo.drq
./drnq run examples/full_drncq_demo.drq
```

Kaynak kodunu kendi bytecode biçimine derleyip çalıştırmak:

```sh
./drnq compile examples/classes.drq -o classes.drnb
./drnq exec classes.drnb
./drnq ir examples/quantum_gates.drq
```

`drnq` paket içinde verilmiş statik bağlı native Linux x86-64 çalıştırılabilir dosyasıdır. Program çalıştırmak için Python veya C++ derleyicisi gerekmiyor. Kaynak kodu yeniden derlemek için C++17 derleyicisi gerekir.

## Değişkenler ve hesaplama

İstenen değişken bildirim biçimi:

```text
DRNCQ = "sayi", 12;
DRNCQ = "etiket", "DRNC-Q";
DRNCQ = "aktif", true;
DRNCQ = "psi", superposfonk();

sayi = (sayi + 3) * 2;
if (aktif && sayi > 10) {
    print(etiket + " hesap sonucu=" + sayi);
} else {
    print("koşul sağlanmadı");
}
```

`DRNCQ` evrensel dinamik değişken taşıyıcısıdır; çalışma zamanında `number`, `string`, `bool`, `null`, `list`, kullanıcı sınıfı nesnesi veya kuantum register tutamacı taşıyabilir. `type(value)` türü bildirir. Bildirim adları tırnak içinde yazılır ve ASCII tanımlayıcı kurallarına uymalıdır. Blok/function yerel bildirimleri desteklenir.

Desteklenen yapılar: `if / else if / else`, `for`, `while`, `break`, `continue`; fonksiyon, özyineleme ve `return`; sınıflar ve metotlar; listeler ve indeksleme; `import`; `try / catch / throw`; kısa devreli `&&` / `||`; `null`; matematik ve standart kütüphane. Dilin tam grameri ve sınırları `LANGUAGE_SPEC.md` dosyasındadır.

## Fonksiyon ve sınıf örneği

```text
fn factorial(n) {
    if (n <= 1) { return 1; }
    return n * factorial(n - 1);
}

class Vector2 {
    fn init(self, x, y) {
        self.x = x;
        self.y = y;
    }
    fn length(self) {
        return sqrt(self.x * self.x + self.y * self.y);
    }
}

DRNCQ = "f", factorial(6);
DRNCQ = "v", Vector2(3, 4);
print(f);          # 720
print(v.length()); # 5
```

Metotların ilk parametresi `self` olmalıdır. Nesne alanları dinamik olarak atanır; `new Vector2(3, 4)` sözdizimi de geçerlidir.

## Kuantum dili

Kullanıcı kuantum durumlarını `0`, `1`, `01`, `10` şeklinde bit dizileri yazarak tanımlamaz. İlişkisel EVET/HAYIR sektörü ve bileşim bazları çalışma zamanı tarafından üretilir. Sayılar `0` ve `1` genel hesaplamada elbette kullanılabilir; bunlar kuantum-baz literal'ı değildir.

```text
show_basis();
DRNCQ = "q", superposfonk();
DRNCQ = "bell", donfonk();
DRNCQ = "branch", zeryafonk(q);
assert_normalized(q);
verify_entanglement(bell);
modular_status();
```

Temel işlemler:

| İşlem | Davranış |
|---|---|
| `qubitfonk()` | İçsel EVET baz durumunda qubit oluşturur. |
| `superposfonk([phase])` | Normalize edilmiş EVET/HAYIR süperpozisyonu üretir; faz radyandır. |
| `donfonk()` | İki-qubit Bell-tipi durum üretir; ilk qubit tutamacını döndürür. `partner(q)` ikinci qubit tutamacını verir. |
| `donfonk(q1, q2)` | İki uyumlu tek-qubit durumuna H ve kontrollü-X uygular. |
| `zeryafonk(q)` | Yeni DAL+/DAL− sektörü ekler ve kaynak qubit ile kontrollü-X uygular. |
| `hgate`, `xgate`, `zgate` | Tek-qubit H/X/Z işlemleri. |
| `phasegate`, `rxgate`, `rygate`, `rzgate` | Faz ve eksen etrafı rotasyonları; açı radyandır. |
| `cxgate`, `czgate`, `swapgate` | İki-qubit kapıları. Bağımsız register'lar gerektiğinde ortak register'da birleştirilir. |
| `measure(q)` | Durumu sektör bazında ölçer/çöker ve sektör etiketi döndürür. |
| `probability(q, label)` | Quibit sektör etiketinin olasılığını döndürür. |
| `norm(q)`, `assert_normalized(q)` | Ortak register norm karesini döndürür/doğrular. |
| `verify_entanglement(q [, partner])` | İndirgenmiş saflık üzerinden dolanıklık testi yapar. |
| `evrimfonk(q [, ds])`, `moduleradim([ds])` | Dahili modüler parametreyi ilerletir ve canlı register'ları evriltir. |
| `teleportfonk(source, destination)` | Yerel simülatörde Bell çifti, ölçümler ve koşullu düzeltmelerle mantıksal teleportasyon uygular. |

`cxgate`, `czgate`, `swapgate`, `donfonk(q1,q2)` ve `teleportfonk` referans güncelleyebilmek için doğrudan değişken adları alır. `zeryafonk` kaynak qubit tutamacını alır. Detaylı semantik ve sınırlamalar şartnamede listelenmiştir.

## Modüler zaman

Modüler parametre `modular_s` sanal makinenin içindedir; harici sistem saati veya saniye olarak yorumlanmaz. Kuantum durum üretimi, gate/branch/measurement ve açık `moduleradim`/`evrimfonk` komutları modüler akışı ilerletir. Salt-okuma `print`, `type`, `norm`, `probability`, `show_basis` ve `modular_status` işlemleri zaman ilerletmez. Gate işlemi uygulandıktan sonra simülatörün ilişkisel spektrumuna göre dahili faz evrimi yapılır.

Bu modüler eşleme v1.0 çalışma semantiğinin açık bir tasarım kuralıdır; bütün fiziksel teorinin veya gerçek cihaz dinamiğinin DRNC aksiyomlarından kanıtlandığı iddia edilmez. `s` boyutsuzdur.

## Standart kütüphane

- Matematik: `pi()`, `abs`, `sqrt`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `exp`, `log`, `log10`, `floor`, `ceil`, `round`, `pow`, `min`, `max`.
- Tipler / kontrol: `type`, `assert`, `to_number`, `to_string`.
- Listeler: `len`, `get`, `set`, `push`, `pop`, `contains`.
- Metinler: `upper`, `lower`, `substr`, `split`, `join`, `contains`.
- Konsol ve dosyalar: `print`, `yaz`, `input`, `read_file`, `write_file`, `file_exists`.
- Kuantum durumları: `show_basis`, `modular_status`, `norm`, `assert_normalized`, `verify_entanglement`, `measure`, `probability`, `same_register`, `partner`.

Dosya işlevleri programı çalıştıran işletim sistemi kullanıcısının erişebildiği dosyalara erişir; otomatik sandbox değildir. Kaynak ve dosya metni üst sınırı 8 MiB'dir. Metin `len` / indeksleme işlemleri UTF-8 kod noktaları değil baytlar üzerinde çalışır; `upper`/`lower` ASCII odaklıdır.

## Derleyici ve güvenlik sınırları

- Kaynak çözümleme, sembol/kapsam ve fonksiyon/constructor arite denetimleri `check`/`compile` sırasında yapılır.
- Bytecode `DRNQB3` magic/sürümünü, sınıf ve fonksiyon tablolarını, opcode ve atlama sınırlarını, boyut limitlerini ve CRC-32 toplamını içerir. CRC bozulmayı yakalar; imza değildir.
- Kaynak 8 MiB, bytecode 64 MiB, talimat 1.000.000, çağrı derinliği 256, VM talimat bütçesi 2.000.000 ve state-vector register başına 16 qubit ile sınırlandırılmıştır.
- Dil dinamik tiplidir: isim ve yapı denetimi derleme sırasında, değerlerin gerçek türüne bağlı işlemler çalışma sırasında denetlenir. Hatalar satır ve opcode bağlamıyla raporlanır. Liste/nesne referans döngüsü oluşturacak atamalar reddedilir; bu, genel bir sandbox yerine bellek ve gösterim döngülerine karşı bir korumadır.

## Derleme / test

```sh
make
make check
```

`make check` fonksiyon özyinelemesi, sınıflar/metotlar, modül import'u, kapsam, listeler, dosya/konsol I/O, hata yakalama, bytecode round-trip/bozulma reddi, gate dizileri, dolanıklık, dallanma, modüler akış ve teleportasyon simülasyonunu otomatik test eder. ASan/UBSan denetimi için:

```sh
g++ -std=c++17 -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer drnq.cpp -o drnq-sanitize
./drnq-sanitize run examples/full_drncq_demo.drq
```

## Fiziksel kuantum işlemcisi hakkında

Bu paket bağımsız dil/VM ve yerel kuantum simülatörüdür; bulut API'si çağırmaz. Gerçek QPU'da yürütme için hedef qubit teknolojisine özgü, kalibre edilmiş darbe kontrolü, readout elektroniği ve uyumlu kontrol firmware'i gerekir. v1.0 ana derleyicisi henüz DRNQB3 programlarının tamamını fiziksel QPU komutlarına indirgeyen genel bir arka uç içermez. Teleportasyon ve ölçümler bu pakette klasik state-vector simülatöründe çalışır; gerçek donanım deneyi olarak sunulmaz.
