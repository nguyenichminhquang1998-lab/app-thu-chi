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
- Đính kèm ảnh hoá đơn cho giao dịch
- Nhập ghi chú bằng giọng nói
- Đa tiền tệ theo ví (tỷ giá quy đổi có thể chỉnh trong phần cài đặt)
- Xuất báo cáo CSV/PDF
- Khoá ứng dụng bằng mã PIN hoặc vân tay/Face ID
- Tuỳ chỉnh ngày bắt đầu tháng (cho người nhận lương giữa tháng), chế độ tối

**Có chủ đích không làm trong bản này**
- *Chia sẻ sổ thu chi với gia đình/nhóm*: bỏ qua theo yêu cầu vì đây là app dùng cá nhân.
- *Widget màn hình chính/khoá màn hình*: cần viết code gốc riêng cho Android (App Widget) và iOS (WidgetKit) và kiểm thử trên thiết bị thật — nằm ngoài khả năng kiểm chứng của môi trường phát triển hiện tại.
- *Tự động đọc SMS ngân hàng để tạo giao dịch*: chỉ khả thi trên Android, đòi hỏi quyền truy cập SMS khá nhạy cảm và cần kiểm thử kỹ trên thiết bị thật trước khi bật; để tránh rủi ro về quyền riêng tư khi chưa kiểm thử được, tính năng này chưa được triển khai.
- *OCR nhận diện hoá đơn*: app đã hỗ trợ đính kèm ảnh hoá đơn; việc tự động trích xuất số tiền/văn bản từ ảnh bằng ML Kit cần thêm thư viện nặng và huấn luyện/kiểm thử độ chính xác trên thiết bị thật nên chưa đưa vào bản này.

## Kiến trúc

- **Flutter** (Dart), state management bằng `provider`
- **SQLite** (`sqflite`) làm nguồn dữ liệu chính: bảng `wallets`, `categories`, `tx_entries`, `budgets`, `recurring_transactions`, `savings_goals`
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

> Môi trường phát triển hiện tại không có Android SDK/máy ảo hay thiết bị thật để build và chạy ứng dụng thực tế — mã nguồn đã được xác minh bằng `flutter analyze` (không lỗi) và bộ unit test cho tầng dữ liệu/logic thuần. Trước khi phát hành, nên build và kiểm thử thủ công trên thiết bị Android/iOS thật.
