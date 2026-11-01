# Quy Trình Chuẩn Đóng Gói, Commit, Push & Phát Hành Veo3

Tài liệu này là **Quy chuẩn vận hành chuẩn (SOP)** để phát hành phiên bản mới cho ứng dụng **Veo3 Thỏ và nhím**, đảm bảo không bao giờ bị sót bước, link tải luôn hoạt động 100%, hệ thống tự động cập nhật hoạt động ổn định, và repo `veo_version` luôn gọn gàng (chỉ lưu bản mới nhất, tự động dọn sạch bản cũ).

---

## 🎯 Định Dạng Link Public Chuẩn Để Phát Hành

Mỗi bản phát hành sẽ có link tải trực tiếp công khai theo chuẩn GitHub Media / Releases:

```text
https://media.githubusercontent.com/media/nguyenzuanthuy/veo_version/main/Veo3-Tho-va-nhim-Setup-<VERSION>.exe?v=<VERSION>
```

*Ví dụ bản v1.0.4:*  
👉 `https://media.githubusercontent.com/media/nguyenzuanthuy/veo_version/main/Veo3-Tho-va-nhim-Setup-1.0.4.exe?v=1.0.4`

---

## 📋 Checklist 6 Bước Phát Hành (Không Thể Bỏ Sót)

```
[ ] BƯỚC 0: Kiểm tra CSDL (Nếu có đổi schema ➜ Bắt buộc thêm ALTER TABLE vào prisma.ts & cập nhật template db)
[ ] BƯỚC 1: Cập nhật số phiên bản (3 files: package.json, package-lock.json, appVersion.ts)
[ ] BƯỚC 2: Chạy script đóng gói build bộ cài .exe (Tự động sync bản mới & dọn bản cũ)
[ ] BƯỚC 3: Commit & Push mã nguồn (Repo veo3: branch developer ➜ PR sang main)
[ ] BƯỚC 4: Push phiên bản mới & Xóa phiên bản cũ (Repo veo_version)
[ ] BƯỚC 5: Nghiệm thu (Test link tải & Test cập nhật một chạm)
```

---

## Chi Tiết Từng Bước Thực Hiện

### 🔹 BƯỚC 0: Kiểm tra CSDL & Migration (BẮT BUỘC NẾU CÓ ĐỔI SCHEMA)

> [!CAUTION]
> **Lưu ý sống còn:** Máy người dùng đang cài bản cũ có file CSDL cá nhân tại `%APPDATA%\veo3-tho-va-nhim\veo3.db`. CSDL này **không tự động nhận cột mới** nếu chỉ sửa `schema.prisma`. Nếu thiếu bước này, khi app update lên sẽ bị lỗi SQLite `no such column`, dẫn đến API crash 500 và màn hình báo *"Không tìm thấy dự án"*!

Khi có bất kỳ thay đổi nào trong `prisma/schema.prisma` (thêm bảng, thêm cột):
1. **Thêm lệnh `ALTER TABLE` vào [`src/lib/prisma.ts`](file:///c:/Users/nguye/OneDrive/文档/veo3-tho-va-nhim/public-veo3/src/lib/prisma.ts):**
   Trong hàm `ensureDbInitialized()`, thêm lệnh tương ứng:
   ```typescript
   await basePrisma.$executeRawUnsafe('ALTER TABLE "GenJob" ADD COLUMN "tenCotMoi" TEXT;').catch(() => { });
   ```
2. **Cập nhật cả 2 file database template:**
   Chạy lệnh bổ sung cột vào `prisma/veo3.template.db` và `prisma/veo3.db` để người dùng mới cài lần đầu cũng có CSDL chuẩn.
3. **Chạy `npx prisma generate`** để sinh lại Prisma Client trước khi build.

---

### 🔹 BƯỚC 1: Nâng phiên bản (Bump Version)

Cần cập nhật đồng bộ số phiên bản `X.Y.Z` ở 3 file trong thư mục `public-veo3`:

1. **`public-veo3/package.json`**:
   ```json
   "version": "1.0.4"
   ```
2. **`public-veo3/package-lock.json`**:
   ```json
   "version": "1.0.4"
   ```
3. **`public-veo3/src/lib/appVersion.ts`**:
   ```typescript
   export const CURRENT_APP_VERSION = '1.0.4';
   ```

---

### 🔹 BƯỚC 2: Đóng gói bản cài đặt (Build Installer)

Mở terminal tại thư mục `public-veo3` và chạy:

```powershell
cd "c:\Users\nguye\OneDrive\文档\veo3-tho-va-nhim\public-veo3"
powershell -ExecutionPolicy Bypass -File scripts/build_app.ps1
```

Script này sẽ tự động:
1. Dọn dẹp bản build cũ và đóng các tiến trình đang chiếm file lock.
2. Build Next.js Production (`npm run build:next`).
3. Chuẩn bị standalone bundle và assets (`prepare-standalone.js`).
4. Đóng gói bộ cài đặt NSIS `.exe`, `.blockmap` và `latest.yml`.
5. Tự động sao chép thành phẩm mới sang thư mục `veo_version`.
6. **Tự động xóa các file `.exe` và `.blockmap` của phiên bản cũ** trong `veo_version` để không bị tích lũy dung lượng.
7. Tự động inject URL Git LFS kèm query param chống cache CDN vào `latest.yml`.

---

### 🔹 BƯỚC 3: Quy tắc Commit & Push Mã Nguồn (`veo3`)

#### 1. Quy chuẩn Commit Message (Conventional Commits)
- `release: vX.Y.Z - bump version and release features` (khi phát hành bản mới)
- `feat: <mô tả tính năng>` (tính năng mới)
- `fix: <mô tả lỗi>` (sửa lỗi)
- `chore: <mô tả>` (cập nhật config, dọn dẹp)

#### 2. Luồng nhánh (Branch & PR):
- **Nhánh làm việc:** `developer`
- **Nhánh chính thức:** `main`

```powershell
cd "c:\Users\nguye\OneDrive\文档\veo3-tho-va-nhim\public-veo3"
git add .
git commit -m "release: v1.0.4 - bump version and release features"
git push origin developer
```

> **Tạo Pull Request (PR) đồng bộ sang `main`:**
> 1. Mở GitHub repo: `https://github.com/nguyenzuanthuy/veo3`
> 2. Chọn **New Pull Request**: `base: main` ⬅ `compare: developer`
> 3. Kiểm tra code diff và nhấn **Merge Pull Request** để đồng bộ `main`.

---

### 🔹 BƯỚC 4: Push Bản Mới & Xóa Bản Cũ Trên `veo_version`

Quy tắc chuẩn: **Chỉ lưu giữ bản mới nhất trên repo `veo_version`, các file cũ sẽ tự động được xóa bỏ khỏi Git để tiết kiệm dung lượng.**

#### Cách 1: Chạy Script Tự Động 1 Lệnh (Khuyên Dùng - Nhanh & Chuẩn Nhất)
Chạy script tự động nhận diện version, stage xóa bản cũ, add bản mới, commit, push git và Git LFS:

```powershell
cd "c:\Users\nguye\OneDrive\文档\veo3-tho-va-nhim\public-veo3"
powershell -ExecutionPolicy Bypass -File scripts/push_release.ps1
```

#### Cách 2: Thao Tác Bằng Lệnh Git Thủ Công
```powershell
cd "c:\Users\nguye\OneDrive\文档\veo3-tho-va-nhim\veo_version"

# 1. Stage toàn bộ thay đổi (git add -A tự động ghi nhận file mới và nhận diện xóa file ver cũ)
git add -A

# 2. Commit
git commit -m "release: v1.0.4 - update installer and remove old versions"

# 3. Push code và binary Git LFS
git push origin main
git lfs push --all origin main

# 4. Gắn tag cho phiên bản mới
git tag -a "v1.0.4" -m "Release v1.0.4" -f
git push origin "v1.0.4" -f
```

*(Lưu ý: Dùng `git add -A` thay vì `git add *.exe*` để Git ghi nhận cả hành động xóa bỏ các file ver cũ).*

---

### 🔹 BƯỚC 5: Nghiệm Thu & Kiểm Tra (Verification)

1. **Kiểm tra file cấu hình cập nhật:**
   ```powershell
   curl.exe -I -m 10 "https://raw.githubusercontent.com/nguyenzuanthuy/veo_version/main/latest.yml"
   ```
   *(Phải trả về HTTP 200 OK).*

2. **Kiểm tra Link tải bộ cài trực tiếp:**
   ```powershell
   curl.exe -I -m 10 "https://media.githubusercontent.com/media/nguyenzuanthuy/veo_version/main/Veo3-Tho-va-nhim-Setup-1.0.4.exe?v=1.0.4"
   ```
   *(Phải trả về HTTP 200 OK kèm dung lượng ~406 MB).*

3. **Kiểm tra Auto-Update trên Tool máy khách:**
   - Mở ứng dụng Veo3 bản cũ.
   - Góc trái bên dưới hiện thông báo có bản mới: `Bản v1.0.4 [Cập nhật]`.
   - Nhấn nút **Cập nhật** ➜ Phần trăm tải chạy từ `0%` ➜ `100%` ➜ App tự khởi động lại và nâng cấp lên `v1.0.4`.
