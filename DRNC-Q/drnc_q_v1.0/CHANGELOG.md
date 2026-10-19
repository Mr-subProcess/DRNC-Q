# Değişiklik günlüğü

## v1.0 — tam dil çekirdeği

- Sürümlendirilmiş özel bytecode kapsayıcısı `DRNQB3` kullanılır; CRC, boyut sınırları, opcode ve giriş noktası kontrolleri uygulanır.
- `DRNCQ = "name", expression;` bildirimleri, global ve leksik yerel kapsamlar, dinamik değer taşıyıcısı ve `null` eklendi.
- Aritmetik, karşılaştırma, kısa devreli mantık, matematik fonksiyonları ve ayrıntılı runtime hata mesajları tamamlandı.
- `if/else if/else`, `for`, `while`, `break`, `continue` ve VM adım limiti kapsandı.
- Kullanıcı tanımlı fonksiyonlar, dönüş, özyineleme, sınıflar, `self` tabanlı metotlar, nesne alanları ve `new` kurucuları eklendi.
- Modül import'u, döngüsel import koruması, listeler/indeksler ve `try/catch/throw` eklendi.
- Standart kütüphaneye metin, liste, konsol ve sınırlı dosya I/O işlevleri eklendi.
- State-vector simülatörüne H/X/Z, PHASE/RX/RY/RZ, CX/CZ/SWAP; nested list/object içindeki QRef alias güncellemesi eklendi.
- DRNC EVET/HAYIR sektörleri, süperpozisyon, dolanıklık, Zerya dallanması, modüler akış, ölçüm ve teleportasyon simülasyonu korundu.
- Sınıf/metot, bytecode round-trip, checksum reddi, standard library, modüler kuantum akış ve negatif derleme testleri eklendi.
- Fiziksel QPU backend'i bu sürümün kapsamı dışında tutulur; simülatör sonuçları donanım deneyi olarak sunulmaz.
