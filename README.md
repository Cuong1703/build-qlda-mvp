# BUILD QLDA — MVP Demo

Website tĩnh (HTML/CSS/JS thuần, không cần build) gồm:
- `index.html` — Landing page giới thiệu
- `app.html` — Ứng dụng demo (đăng nhập → dashboard, dự án, tiến độ, dòng tiền, báo cáo, cài đặt)

## Bước 2 — Đưa lên GitHub

```bash
cd build-qlda-mvp
git init
git add .
git commit -m "Init BUILD QLDA MVP"
git branch -M main
git remote add origin https://github.com/<ten-user>/build-qlda-mvp.git
git push -u origin main
```
> Tạo repo trống trước tại github.com/new (không tick "Add README").

## Bước 3 — Deploy lên Vercel (miễn phí)

1. Vào vercel.com → **Add New → Project**
2. Chọn **Import Git Repository** → chọn repo `build-qlda-mvp` vừa tạo
3. Framework Preset chọn **Other** (vì đây là static HTML, không cần build command)
4. Nhấn **Deploy** — sau ~30 giây sẽ có link dạng `build-qlda-mvp.vercel.app`

Mỗi lần bạn `git push` lên GitHub, Vercel sẽ tự động deploy lại bản mới.

## Bước 4 — Supabase: nâng cấp demo tĩnh → ứng dụng thật

Bản `app.html` cũ dùng dữ liệu mock viết cứng. File **`app-live.html`** đã được nối vào Supabase thật:
đăng nhập thật (Supabase Auth), dự án/tiến độ/dòng tiền đọc — ghi trực tiếp vào database.

### 4.1 Tạo project Supabase
1. Vào supabase.com → **New project** → đặt tên, chọn mật khẩu DB, chọn khu vực gần VN (Singapore).
2. Vào **SQL Editor → New query**, dán toàn bộ nội dung file `supabase-schema.sql` → **Run**.
   File này tạo bảng `projects`, `wbs_items`, `transactions`, bật Row Level Security, và chèn sẵn dữ liệu mẫu.
3. Vào **Authentication → Providers**, đảm bảo **Email** đang bật (mặc định đã bật).
4. Vào **Project Settings → API**, copy `Project URL` và `anon public key`.

### 4.2 Điền cấu hình
Mở file `config.js`, thay giá trị mẫu:
```js
const SUPABASE_URL = "https://xxxxxxxxxxxx.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOi...";
```

### 4.3 Tạo tài khoản đăng nhập đầu tiên
Mở `app-live.html` (double-click chạy local, hoặc deploy lên Vercel) → nhấn **"Chưa có tài khoản? Đăng ký"**,
nhập email/mật khẩu → Supabase sẽ gửi email xác nhận (tùy cấu hình có thể tắt xác nhận email trong
Authentication → Settings để test nhanh) → đăng nhập lại.

### 4.4 Những gì đã kết nối thật trong `app-live.html`
| Chức năng | Trạng thái |
|---|---|
| Đăng nhập / Đăng ký | ✅ Supabase Auth thật |
| Danh sách & tạo dự án mới | ✅ Đọc/ghi bảng `projects` |
| Tiến độ (thêm hạng mục, xem % kế hoạch/thực tế) | ✅ Đọc/ghi bảng `wbs_items` |
| Dòng tiền dự án (tạo phiếu thu/chi, xem lịch sử) | ✅ Đọc/ghi bảng `transactions` |
| Dòng tiền toàn công ty | ✅ Tổng hợp từ tất cả dự án |
| Tài liệu, Nhật ký công trình, Báo cáo, Cài đặt/Phân quyền | ⏳ Vẫn là giao diện minh họa (`app.html`) — cần thêm Supabase Storage (tài liệu/ảnh) và bảng `profiles`/quyền chi tiết ở bước sau |

### 4.5 Deploy bản live lên Vercel
Thêm `app-live.html`, `config.js`, `supabase-schema.sql` vào cùng repo GitHub rồi push như Bước 2 —
Vercel sẽ tự deploy lại, truy cập qua đường dẫn `<ten-project>.vercel.app/app-live.html`.

> Lưu ý bảo mật: `anon public key` được thiết kế để lộ ra trình duyệt (an toàn), việc bảo vệ dữ liệu
> nằm ở Row Level Security (RLS) đã bật sẵn trong `supabase-schema.sql`. Trước khi dùng thật cho nhiều
> công ty/khách hàng, nên siết RLS theo `user_id`/vai trò thay vì cho phép mọi user đã đăng nhập xem hết.
