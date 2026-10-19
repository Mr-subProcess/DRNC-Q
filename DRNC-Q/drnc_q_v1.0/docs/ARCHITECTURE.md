# DRNC-Q v1.0 — mimari

## Aşamalar

1. **Lexer**: `.drq` kaynağını konum bilgisini koruyan token'lara dönüştürür.
2. **Parser**: program/fonksiyon/sınıf/deyim/ifade ağacını kurar. Import'lar göreli yoldan yüklenir; döngüsel import reddedilir.
3. **Semantik doğrulama**: değişken kapsamları, yinelenen bildirimler, fonksiyon/constructor aritesi, `return`, `break` ve `continue` bağlamları, sınıf bildirimleri ve özel qubit referansı gerektiren gate çağrıları kontrol edilir.
4. **Bytecode üretimi**: işlem kümesi kendi `DRNQB3` sürümlü dosyasına yazılır; class/fonksiyon tablosu ve CRC-32 eklenir.
5. **Decoder/VM**: dosya boyutu, magic, sürüm, checksum, opcode, sayısal sonluluk, jump hedefleri ve fonksiyon girişleri doğrulanır; sınırlı bir operand stack ile yürütülür.
6. **DRNC-Q state-vector çalışma zamanı**: EVET/HAYIR sektörleri, DAL etiketleri ve kuantum genlikleri ortak kompleks state-vector register'larında tutulur. Dolanıklık işlemleri bağımsız register'ları tensor product ile birleştirir ve tüm erişilebilir `QRef` alias'larını günceller.

## Modüler akış semantiği

Global `modular_s` boyutsuz bir parametredir. Durum üretimi, kuantum kapıları, Zerya dallanması, ölçüm ve açık evrim adımlarında tüm yaşayan register'lara sektör enerjileriyle belirlenen birim modüllü faz uygulanır. Salt-okuma fonksiyonları akışı ilerletmez.

Bu semantik programlama dili içindeki açık bir operasyonel kuraldır; fiziksel saniyelerle özdeşlik veya DRNC aksiyomlarının tam fiziksel ispatı olduğu iddia edilmez.

## Bellek ve yürütme sınırları

- VM adım bütçesi: 2,000,000.
- Çağrı derinliği: 256.
- State-vector register başına maksimum 16 qubit.
- Kaynak dosya: 8 MiB; bytecode dosyası: 64 MiB.
- Liste: en fazla 1,000,000 eleman.
- Liste/nesne referans döngüleri çalışma zamanında reddedilir; VM ayrıca kapanırken kayıtlı konteynerleri temizler.
- Dosya I/O yalnızca yerel işletim sistemi çağrısıdır; sandbox değildir.

## Kuantum işlemlerinin doğruluk kapsamı

H/X/Z, faz, RX/RY/RZ, CX/CZ/SWAP kapıları kompleks genlikler üzerinde uygulanır. Ölçüm klasik PRNG ile Born olasılıklarına göre örneklenir. `teleportfonk` simülatörde Bell çifti, ortak iki-qubit etkileşim, ölçüm ve koşullu Pauli düzeltmelerini taklit eder. Bunların hiçbiri tek başına gerçek kuantum işlemci kontrolü, pulse kalibrasyonu veya fiziksel deney ispatı değildir.
