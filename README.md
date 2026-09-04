# App Thu Chi

Ứng dụng quản lý thu chi cá nhân, xây dựng bằng Flutter, lấy cảm hứng từ các app thu chi phổ biến (Money Lover, EasyBudget...) và bổ sung các tính năng giúp người dùng hình thành thói quen quản lý tài chính.

## Tính năng

**Cốt lõi**
- Thêm/sửa/xoá giao dịch thu, chi (số tiền, danh mục, ví, ngày giờ, ghi chú, chủ đề)
- Nhiều ví/tài khoản (tiền mặt, ngân hàng, thẻ, ví điện tử) và chuyển tiền giữa các ví
- Danh mục thu/chi tuỳ biến: icon, màu sắc, sắp xếp thứ tự
- Gắn nhãn mức độ ưu tiên cho danh mục chi tiêu: **Cần thiết / Mong muốn / Loại bỏ**
- Sổ giao dịch xem theo kỳ (tháng), tìm kiếm theo ghi chú/chủ đề
- Biểu đồ: phân loại theo danh mục (biểu đồ tròn) và xu hướng thu/chi theo thời gian (biểu đồ đường + bảng chi tiết)
- Sao lưu/khôi phục toàn bộ dữ liệu qua file JSON

**Nâng cao**
- Ngân sách theo danh mục hoặc tổng thể, cảnh báo khi sắp/đã vượt ngân sách
- Giao dịch định kỳ (hằng ngày/tuần/tháng/năm), tự động sinh giao dịch khi đến hạn
- Nhắc nhở ghi chép chi tiêu hằng ngày (thông báo cục bộ, có thể tuỳ chỉnh giờ)
- Mục tiêu tiết kiệm: đặt mục tiêu, nạp tiền, theo dõi tiến độ
- Ô nhập số tiền kiêm máy tính bỏ túi (cộng/trừ/nhân/chia ngay khi ghi giao dịch)
- Đa tiền tệ theo ví (tỷ giá quy đổi có thể chỉnh trong phần cài đặt)
- Xuất báo cáo CSV/PDF
- Khoá ứng dụng bằng mã PIN hoặc vân tay/Face ID
- Tuỳ chỉnh ngày bắt đầu tháng (cho người nhận lương giữa tháng), chế độ tối

**Có chủ đích không làm trong bản này**
- *Chia sẻ sổ thu chi với gia đình/nhóm*: bỏ qua theo yêu cầu vì đây là app dùng cá nhân.
- *Đính kèm ảnh hoá đơn* và *nhập ghi chú bằng giọng nói*: đã gỡ theo yêu cầu sau khi dùng thử thực tế.
- *Widget màn hình chính/khoá màn hình*: cần viết code gốc riêng cho Android (App Widget) và iOS (WidgetKit) và kiểm thử trên thiết bị thật — nằm ngoài khả năng kiểm chứng của môi trường phát triển hiện tại.
- *Tự động đọc SMS ngân hàng để tạo giao dịch*: chỉ khả thi trên Android, đòi hỏi quyền truy cập SMS khá nhạy cảm và cần kiểm thử kỹ trên thiết bị thật trước khi bật; để tránh rủi ro về quyền riêng tư khi chưa kiểm thử được, tính năng này chưa được triển khai.
- *OCR nhận diện hoá đơn*: cần thêm thư viện nặng và kiểm thử độ chính xác trên thiết bị thật nên chưa đưa vào bản này.

## Bản web (PWA)

Địa chỉ: **https://nguyenichminhquang1998-lab.github.io/app-thu-chi/**

Trên iPhone: mở link bằng Safari → bấm nút **Chia sẻ** → chọn **"Thêm vào MH chính"**. App sẽ chạy toàn màn hình như app thật, không cần cài đặt, không cần chữ ký Apple, không bao giờ hết hạn.

### ⚠️ Dữ liệu bản web và bản điện thoại HOÀN TOÀN TÁCH BIỆT

Bản web lưu dữ liệu bằng SQLite/WebAssembly trong **IndexedDB của trình duyệt**; bản native lưu trong file SQLite riêng của app trên máy. Hai kho này **không tự đồng bộ** và không thấy dữ liệu của nhau.

Muốn chuyển dữ liệu giữa hai bản, làm thủ công qua file JSON:
1. Ở bản nguồn: **Cài đặt → Sao lưu dữ liệu → JSON**.
2. Chuyển file `app-thu-chi-backup-....json` sang thiết bị đích (AirDrop, email, Tệp…).
3. Ở bản đích: **Cài đặt → Khôi phục dữ liệu** → chọn file JSON đó. (Thao tác này **xoá sạch** dữ liệu hiện có ở bản đích rồi thay bằng dữ liệu trong file.)

Chỉ định dạng **JSON** khôi phục được; CSV và Markdown chỉ để xem/lưu trữ.

### Giữ dữ liệu bản web an toàn
- **Bắt buộc thêm vào Màn hình chính.** Safari trên iOS xoá sạch dữ liệu của một website sau 7 ngày không dùng tới; web app đã thêm vào Màn hình chính thì được miễn trừ. App sẽ tự hiện cảnh báo nếu phát hiện đang chạy trong tab trình duyệt thường.
- Xoá dữ liệu duyệt web / "Clear site data" sẽ **xoá luôn sổ thu chi bản web** → hãy xuất JSON định kỳ (app sẽ nhắc nếu quá 14 ngày chưa sao lưu).

### Khác biệt so với bản native
- **Nhắc nhở ghi chép hằng ngày**: không có trên web (trình duyệt không chạy nền đáng tin khi app đã đóng). Bản native giữ đầy đủ.
- **Mở khoá bằng vân tay / Face ID**: không có trên web; khoá bằng mã PIN vẫn hoạt động. Lưu ý mã PIN trên web chỉ có tác dụng che mắt vì dữ liệu nằm trong trình duyệt.
- **Xuất file**: trên web file được **tải xuống** thay vì mở bảng chia sẻ của hệ điều hành.
- Mọi tính năng còn lại đều đầy đủ như bản native.

## Kiến trúc

- **Flutter** (Dart), state management bằng `provider`
- **SQLite** làm nguồn dữ liệu chính: bảng `wallets`, `categories`, `tx_entries`, `budgets`, `recurring_transactions`, `savings_goals`. Cùng một schema và cùng một tầng repository chạy trên cả 3 nơi: plugin `sqflite` (điện thoại), `sqflite_common_ffi_web` (trình duyệt), `sqflite_common_ffi` (khi chạy test)
- `SettingsState` lưu tuỳ chọn người dùng qua `shared_preferences`
- `AppState` là nguồn dữ liệu trung tâm trong bộ nhớ, các màn hình đọc/ghi qua đây

Cấu trúc thư mục chính trong `lib/`:

```
models/        Các model dữ liệu thuần (Wallet, Category, TxEntry, Budget, ...)
data/          Tầng dữ liệu: AppDatabase (schema sqflite), repositories, seed data mặc định
state/         AppState và SettingsState (ChangeNotifier)
services/      Notification, backup/export, PIN/sinh trắc học
screens/       Toàn bộ màn hình UI, tổ chức theo tính năng
widgets/       Widget dùng chung
utils/         Định dạng ngày/tiền tệ, bảng màu, icon, tiện ích khoảng thời gian
platform/      Những chỗ web và điện thoại buộc phải khác nhau (chọn backend
               database, xuất file, kiểm tra độ bền lưu trữ) — mỗi thứ có một
               facade `x.dart` chọn giữa `x_io.dart` và `x_web.dart`
```

## Phát triển

```bash
flutter pub get
flutter run
```

Chạy kiểm thử:

```bash
flutter analyze
flutter test
```

Chạy/build bản web:

```bash
dart run sqflite_common_ffi_web:setup   # chỉ chạy lại khi nâng sqflite_common_ffi_web
flutter run -d chrome
flutter build web --release --base-href /app-thu-chi/
```

`web/sqflite_sw.js` và `web/sqlite3.wasm` được **commit vào repo** để CI build offline được và tái lập chính xác. Khi nâng version `sqflite_common_ffi_web` thì phải chạy lại lệnh setup và commit lại hai file này.

Bản web được GitHub Actions tự build và deploy mỗi khi có commit vào `main` (`.github/workflows/deploy-web.yml`). Bản iOS chưa ký vẫn build bằng workflow cũ chạy tay (`.github/workflows/build-ios-unsigned.yml`).

> Môi trường phát triển hiện tại không có Android SDK/máy ảo hay thiết bị thật để build và chạy ứng dụng thực tế — mã nguồn đã được xác minh bằng `flutter analyze` (không lỗi) và bộ unit test cho tầng dữ liệu/logic thuần. Trước khi phát hành, nên build và kiểm thử thủ công trên thiết bị Android/iOS thật.
