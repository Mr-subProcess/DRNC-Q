# DRNC-Q v1.0 — dil şartnamesi

Bu dosya v1.0 dilinin uygulanmış çekirdek davranışını tanımlar. Bu sürümdeki kaynak derleyicisi `drnq.cpp`, `DRNQB3` bytecode okuyucu/yazarı ve VM davranışı birbiriyle test edilir. Buradaki kuantum semantiği yerel simülatör içindir; fiziksel QPU doğruluğu anlamına gelmez.

## 1. Kaynak / lexing

- Kaynak dosyası `.drq`; maksimum 8 MiB.
- İsimler: `[A-Za-z_][A-Za-z0-9_]*`.
- Sayılar: sonlu ondalık veya bilimsel gösterim (`2`, `3.14`, `1e-5`).
- Metin sabiti `"..."`; escape dizileri `\n`, `\t`, `\r`, `\\`, `\"`.
- Yorumlar `#` ya da `//` ile satır sonuna kadar.
- Sözdiziminde noktalı virgül kullanan ifadeler için `;` zorunludur.
- Özel kuantum durumlarını tanımlayan `0`, `1`, `01`, `10` bit-literal sözdizimi yoktur. `0` ve `1` sayısal literal olarak normal matematikte geçerlidir.

## 2. Gramer (EBNF, kavramsal)

```ebnf
program       = [ "program", identifier, [ ";" ] ], { import | function | class | statement | ";" } ;
import        = "import", string, ";" ;
function      = ( "fn" | "function" ), identifier, "(", [ identifiers ], ")", block ;
class         = "class", identifier, "{", { function }, "}" ;
identifiers   = identifier, { ",", identifier } ;
block         = "{", { statement | ";" }, "}" ;
statement     = declaration | assignment | index-assignment | member-assignment
              | expression, ";"
              | block
              | "if", "(", expression, ")", block, [ "else", ( block | statement ) ]
              | "while", "(", expression, ")", block
              | "for", "(", for-init, ";", expression, ";", for-update, ")", block
              | "return", [ expression ], ";"
              | "break", ";" | "continue", ";"
              | "try", block, "catch", "(", identifier, ")", block
              | "throw", expression, ";" ;
declaration   = "DRNCQ", "=", string, ",", expression, ";" ;
assignment    = identifier, "=", expression, ";" ;
index-assignment = identifier, "[", expression, "]", "=", expression, ";" ;
member-assignment = identifier, ".", identifier, "=", expression, ";" ;
for-init      = identifier, "=", expression | expression ;
for-update    = identifier, "=", expression | expression ;
expression    = literals, variables, list-literal, call, new-object, member, index,
                unary-expression, binary-expression ;
list-literal  = "[", [ expression, { ",", expression } ], "]" ;
call          = identifier, "(", [ expression, { ",", expression } ], ")" ;
new-object    = "new", identifier, "(", [ expression, { ",", expression } ], ")" ;
member        = expression, ".", identifier ;
method-call   = expression, ".", identifier, "(", [ expression, { ",", expression } ], ")" ;
index         = expression, "[", expression, "]" ;
```

EBNF, okuyucunun grameri anlamasına yönelik kısaltılmış gösterimdir; kesin kabul edilen tüm AST kuralları kaynak kodun parser'ında tanımlıdır. Kontrol gövdeleri `{ ... }` blokları olmalıdır. `for` güncelleme ataması önceden tanımlanmış bir değişkene yapılır.

## 3. İfadeler ve operatör önceliği

Düşükten yükseğe:

1. `||` (kısa devre)
2. `&&` (kısa devre)
3. `==`, `!=`
4. `<`, `<=`, `>`, `>=`
5. `+`, `-`
6. `*`, `/`, `%`
7. `^` (sağ birleşimli üs)
8. tekli `+`, `-`, `!`
9. çağrı son ekleri, indeksleme, üye/metot erişimi

`+`, en az bir operand string ise string birleştirir; aksi durumda numeric işlem yapar. `==` aynı türdeki primitive değerleri karşılaştırır; sayı eşitliği IEEE-754 `double` eşitliği kullanır. Diğer aritmetik operandları sayı veya bool olmalıdır; bool sayısal bağlamda 0/1 olarak alınır. Bölme/mod sıfır, negatif reel karekök, geçersiz logaritma veya sonlu olmayan sonuç çalışma zamanı hatasıdır.

## 4. Değişkenler ve kapsama

Kaynak tanımlama formu:

```text
DRNCQ = "name", expression;
```

- Bildirim adı ASCII identifier olmalı, tekrar kullanılabilir bir isim değil aynı kapsamda tekil olmalıdır.
- Global bildirimler global ortamda; fonksiyon ve blok bildirimleri leksik kapsamlarda tutulur. Blok içindeki yerel isim, blok sonrasında görünmez.
- `=` ataması önceden bildirilmiş değişkene yapılır; atama yeni isim oluşturmaz.
- Tek bir `DRNCQ` bildirim tipi dinamik değer taşıyabilir: `number`, `string`, `bool`, `null`, `list`, sınıf örneği veya kuantum `QRef`.
- `type(x)` çalışma anındaki türü (`number`, `string`, `bool`, `null`, `list`, `DRNCQ` ya da sınıf adı) döndürür.
- `pi` ve `modular_s` özel salt-okunur isimlerdir.

## 5. Fonksiyonlar, sınıflar ve modüller

```text
fn factorial(n) {
    if (n <= 1) { return 1; }
    return n * factorial(n - 1);
}

class Vector2 {
    fn init(self, x, y) { self.x = x; self.y = y; }
    fn length(self) { return sqrt(self.x*self.x + self.y*self.y); }
}

DRNCQ = "v", Vector2(3, 4); # new Vector2(3, 4) de geçerli
print(v.length());
```

- Fonksiyonlar konum tabanlı argüman alır; named/default/variadic parametreler yoktur. Özyineleme üst sınırı 256 aktif çağrıdır.
- Her sınıf metodu ilk parametre olarak `self` almalıdır. `init` varsa kurucudur; `init` yoksa sınıf sıfır argümanla oluşturulur.
- Alanlar dinamik atanır ve okunur. Bilinmeyen alan veya metot çalışma zamanı hatasıdır. Kalıtım, erişim düzenleyicileri, static class fields ve generics v1.0 kapsamı dışındadır.
- `import "relative/path.drq";` modülü kök program dosyasına göre çözer. İçe aktarılan modül bildirimleri aynı global isim alanına bağlanır; yinelenen fonksiyon/sınıf/bildirimi hata oluşturur. Döngüsel import reddedilir.

## 6. Hatalar ve standart kütüphane

`try { ... } catch (err) { ... }` çalışma zamanı istisnalarını yakalar; `throw expression;` ifadesi gösterilebilir hataya dönüştürülür ve `err` string olur. Yakalanmayan hata satır, opcode ve açıklamayla programı sonlandırır.

Matematik: `pi()`, `abs`, `sqrt`, `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `exp`, `log`, `log10`, `floor`, `ceil`, `round`, `pow`, `min`, `max`.

Değer/listeler: `type`, `to_number`, `to_string`, `len`, `get`, `set`, `push`, `pop`, `contains`, `assert`.

Metin: `upper`, `lower`, `substr(text,start[,length])`, `split(text,separator)`, `join(list,separator)`. String `len`, indeks ve `substr` UTF-8 baytlarıyla çalışır, Unicode codepoint/grapheme sayımı yapmaz; `upper`/`lower` ASCII odaklıdır.

I/O: `print`, `yaz`, `input([prompt])`, `read_file(path)`, `write_file(path, content)`, `file_exists(path)`. Dosya işlemleri süreç kullanıcısının dosya izinlerine uyar, fakat sandbox sağlamaz. Dosya metni 8 MiB ile sınırlıdır.

## 7. Kuantum semantiği

### 7.1 Otomatik ilişkisel sektörler

VM, baz sektörlerini kullanıcı bit dizisi yazmadan üretir:

- Tek register: `EVET`, `HAYIR`.
- İki register: `(EVET,EVET)`, `(EVET,HAYIR)`, `(HAYIR,EVET)`, `(HAYIR,HAYIR)`.
- Zerya dallanması `DAL+`, `DAL−` etiketleri ekler.

`QRef`, ortak bir state-vector register'ındaki qubit indeksine işaret eder. Register'lar dolanıklık oluşturan işlemlerde tensor-product ile birleştirilir; kaynak değişkenler, listeler ve nesne alanları içindeki bütün referanslar yeni register'a yeniden bağlanır.

### 7.2 Kuantum kurucuları ve işlemleri

- `qubitfonk()` -> `|EVET⟩`.
- `superposfonk([phase])` -> \( (|EVET\rangle + e^{i\,phase}|HAYIR\rangle)/\sqrt2 \).
- `donfonk()` -> \( (|EVET,EVET\rangle + |HAYIR,HAYIR\rangle)/\sqrt2 \); ilk tutamaç döner, `partner(q)` diğerini verir.
- `donfonk(q1,q2)` -> uyumlu tek qubitlerin tensor birleşimi üzerinde `H(q1)`, `CX(q1,q2)`.
- `zeryafonk(q)` -> yeni DAL qubit'i ekler ve kontrollü-X uygular; DAL sektörü enerjileri `+sqrt(3)`, `-sqrt(3)` olarak etiketlenir.
- `hgate(q)`, `xgate(q)`, `zgate(q)`, `phasegate(q,theta)`, `rxgate(q,theta)`, `rygate(q,theta)`, `rzgate(q,theta)`.
- `cxgate(q0,q1)`, `czgate(q0,q1)`, `swapgate(q0,q1)`.
- İki-qubit etkileşim kapıları, register'lar ayrıysa tensor-product ile ortak state-vector oluşturur. Register referansları ortam, kapsam, listeler ve nesne alanları boyunca güncellenir.
- `measure(q)` Born olasılıklarıyla bit seçer, register'ı çökertir ve etiket (`EVET`/`HAYIR`/DAL) döndürür.
- `probability(q,label)` sektörün marjinal olasılığıdır. `norm(q)` register norm karesidir. `verify_entanglement(q)` indirgenmiş iki-sektör saflığını kontrol eder; birden fazla qubitli kayıt için q'nun kaydın geri kalanına göre dolanıklığını tespit eder. İki argüman verildiğinde iki qubit'in aynı kayıtta ve farklı konumda olduğu da doğrulanır.
- `teleportfonk(source,destination)` yerel simülatörde üç qubitli Bell/ölçüm/koşullu düzeltme protokolünü yürütür; destination tutamacı çıktı qubit'ine yeniden bağlanır. Bu bir donanım pulse programı değildir.

State-vector register boyutu en fazla 16 qubit'tir. Kompleks genlikler kullanılır. Ölçüm PRNG tabanlı klasik örneklemedir; gerçek kuantum rastgeleliği veya fiziksel QPU çalıştırması değildir.

### 7.3 Modüler akış

Çalışma zamanı içsel boyutsuz `s` parametresini ve adım sayacını tutar. Başlangıç sektör enerjileri `EVET=1`, `HAYIR=sqrt(2)`; dallanma sektörleri `+sqrt(3)`, `-sqrt(3)` olarak kodlanır. `moduleradim([ds])`, `evrimfonk(q[,ds])`, ölçüm, durum kurucuları ve kapı/dallanma işlemleri global `s`'yi ilerletir; canlı register genliklerine birim modüllü enerji fazı uygular. Salt-okuma işlemleri akışı ilerletmez. `s` saniye değildir ve dış saat kullanılmaz. Enerji atamaları v1.0 model konvansiyonudur; teorik/fiziksel türetimin ispatı olarak yorumlanmamalıdır.

## 8. Derleyici, bytecode ve limitler

Komutlar:

```text
./drnq run file.drq
./drnq check file.drq
./drnq ir file.drq
./drnq compile file.drq -o file.drnb
./drnq exec file.drnb
```

`check` programı çalıştırmaz. `compile` kaynak modüllerini birleştirip `DRNQB3` üretir. Bytecode içinde magic/sürüm, modül adı, fonksiyon imzaları/girişleri, sınıf manifest'i, talimatlar ve CRC-32 vardır; decoder uzunluk, opcode, atlama hedefi, sayısal sonluluk, fonksiyon girişleri ve checksum'u doğrular. CRC-32 güvenilir kaynak veya dijital imza kanıtı değildir.

Sınırlar: 8 MiB kaynak, 64 MiB bytecode, 1.000.000 derlenmiş talimat, VM için 2.000.000 adım, 256 derinlikte çağrı, en fazla 64 fonksiyon argümanı, 1.000.000 elemanlı liste, state-vector başına 16 qubit, dosya metni için 8 MiB.

## 9. Fiziksel donanım sınırı

v1.0 kendi dil, derleyici, bytecode ve simülatörünü içerir; herhangi bir sağlayıcı API'sine bağımlı değildir. Buna karşın genel `DRNQB3` programını bir fiziksel QPU'ya gönderen backend ve uyumlu firmware bu sürümde yoktur. Gerçek donanım için FPGA/kontrol kartı, qubit teknolojisine göre darbe kalibrasyonu, readout elektroniği ve kart firmware'i gereklidir. Bu paket gerçek QPU'da çalıştırma iddiasında bulunmaz.
