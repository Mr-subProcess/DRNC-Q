# DRNC-Q v1.0 — güvenlik notları

- `drnq run` yerel `.drq` kaynağını çalıştırır; bu dilde `read_file`, `write_file` ve `input` bulunduğundan kaynak program işletim sistemi kullanıcısının erişebildiği dosyalara erişebilir. Güvenilmeyen programları çalıştırırken OS sandbox / container kullanın.
- DRNQB3 içindeki CRC-32 bozulmayı saptar; kriptografik imza, kimlik doğrulaması veya yetkilendirme değildir. Güvenilmeyen bytecode dosyalarını çalıştırmayın.
- Kaynak/bytecode boyutları, talimat sayısı, VM adım sayısı, çağrı derinliği, liste uzunluğu ve qubit sayısı sınırlanmıştır; bu sınırlar genel amaçlı güvenli sandbox sağlamaz.
- Dosya yazma işlemi verilen yolda dosyayı oluşturabilir veya üzerine yazabilir. Üretim ortamında uygulama seviyesinde yol izinleri ve işletim sistemi izolasyonu kullanın.
- Yerel ölçümler klasik PRNG kullanır. Bu sürüm kriptografik kuantum rastgele sayı üreteci değildir.
- Fiziksel QPU iletişimi bu sürümün ana executable'ında yoktur; donanım protokolüne ilişkin herhangi bir gerçek cihaz güvenlik özelliği iddia edilmez.
