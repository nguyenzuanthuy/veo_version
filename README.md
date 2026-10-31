# Quy Trình Chuẩn Đóng Gói, Commit, Push & Phát Hành Veo3

Tài liệu này là **Quy chuẩn vận hành chuẩn (SOP)** để phát hành phiên bản mới cho ứng dụng **Veo3 Thỏ và nhím**, đảm bảo không bao giờ bị sót bước, link tải luôn hoạt động 100% và hệ thống tự động cập nhật hoạt động ổn định.

---

## 🎯 Định Dạng Link Public Chuẩn Để Phát Hành

Mỗi bản phát hành sẽ có link tải trực tiếp công khai theo chuẩn GitHub Releases:

```text
https://github.com/nguyenzuanthuy/veo_version/releases/download/v<VERSION>/Veo3-Tho-va-nhim-Setup-<VERSION>.exe
```

*Ví dụ bản v1.0.2:*  
👉 `https://github.com/nguyenzuanthuy/veo_version/releases/download/v1.0.2/Veo3-Tho-va-nhim-Setup-1.0.2.exe`

---

## 📋 Checklist 5 Bước Phát Hành (Không Thể Bỏ Sót)

```
[ ] BƯỚC 1: Cập nhật số phiên bản (3 files)
[ ] BƯỚC 2: Chạy script đóng gói build bộ cài .exe
[ ] BƯỚC 3: Commit & Push mã nguồn (Repo veo3)
[ ] BƯỚC 4: Tạo GitHub Release & Đính kèm file exe (Repo veo_version)
[ ] BƯỚC 5: Nghiệm thu (Test link tải & Test cập nhật một chạm)
```

---

## Chi Tiết Từng Bước Thực Hiện

### 🔹 BƯỚC 1: Nâng phiên bản (Bump Version)

Cần cập nhật đồng bộ số phiên bản `X.Y.Z` ở 3 file trong thư mục `veo3`:

1. **`veo3/package.json`**:
   ```json
   "version": "1.0.2"
   ```
2. **`veo3/package-lock.json`**:
   ```json
   "version": "1.0.2"
   ```
3. **`veo3/src/lib/appVersion.ts`**:
   ```typescript
   export const CURRENT_APP_VERSION = '1.0.2';
   ```

---

### 🔹 BƯỚC 2: Đóng gói bản cài đặt (Build Installer)

Mở terminal tại thư mục `veo3` và chạy:

```powershell
cd "c:\Users\nguye\OneDrive\文档\veo3"
powershell -ExecutionPolicy Bypass -File scripts/build_app.ps1
```

Script này sẽ tự động:
1. Dọn dẹp bản build cũ và đóng các tiến trình đang chiếm file lock.
2. Build Next.js Production (`npm run build:next`).
3. Chuẩn bị standalone bundle và assets (`prepare-standalone.js`).
4. Đóng gói bộ cài đặt NSIS `.exe`, `.blockmap` và `latest.yml`.
5. Tự động sao chép thành phẩm sang thư mục `veo_version`.

*Thành phẩm tạo ra:*
- `dist_out/Veo3-Tho-va-nhim-Setup-<VERSION>.exe`
- `release/Veo3-Tho-va-nhim-Setup-<VERSION>.exe`
- `veo_version/Veo3-Tho-va-nhim-Setup-<VERSION>.exe`

---

### 🔹 BƯỚC 3: Quy tắc Commit & Push Mã Nguồn (`veo3`)

#### 1. Quy chuẩn Commit Message (Conventional Commits)
Sử dụng tiền tố rõ ràng theo mục đích:
- `release: vX.Y.Z - <mô tả ngắn>` (khi phát hành bản mới)
- `feat: <mô tả tính năng>` (tính năng mới)
- `fix: <mô tả lỗi>` (sửa lỗi)
- `chore: <mô tả>` (cập nhật config, dependencies)

#### 2. Luồng nhánh (Branch & PR):
- **Nhánh làm việc:** `developer`
- **Nhánh chính thức:** `main`

```powershell
cd "c:\Users\nguye\OneDrive\文档\veo3"
git add .
git commit -m "release: v1.0.2 - bump version and release features"
git push origin developer
```

> **Tạo Pull Request (PR):**
> 1. Mở GitHub repo: `https://github.com/nguyenzuanthuy/veo3`
> 2. Chọn **New Pull Request**: `base: main` ⬅ `compare: developer`
> 3. Kiểm tra code diff và nhấn **Merge Pull Request** để đồng bộ `main`.

---

### 🔹 BƯỚC 4: Tạo GitHub Release Trên `veo_version`

Để có link download chuẩn `releases/download/...`, thực hiện đưa bộ cài lên GitHub Releases:

#### Cách 1: Thao tác trên giao diện Web GitHub (Khuyên dùng - Rõ ràng & Trực quan)
1. Truy cập: **`https://github.com/nguyenzuanthuy/veo_version/releases/new`**
2. **Choose a tag:** Nhập `v1.0.2` (hoặc phiên bản tương ứng) ➜ Bấm **Create new tag: v1.0.2 on publish**.
3. **Release title:** Nhập `Veo3 Thỏ và nhím v1.0.2`
4. **Description:** Ghi tóm tắt tính năng mới / sửa lỗi của bản này.
5. **Attach binaries:** Kéo thả 2 file sau vào ô tải lên:
   - File 1: `Veo3-Tho-va-nhim-Setup-1.0.2.exe` (trong thư mục `veo_version` hoặc `release`)
   - File 2: `latest.yml`
6. Nhấn nút **Publish release**.

> ✅ **Kết quả:** Ngay lập tức có link tải trực tiếp:
> `https://github.com/nguyenzuanthuy/veo_version/releases/download/v1.0.2/Veo3-Tho-va-nhim-Setup-1.0.2.exe`

#### Cách 2: Đẩy repo Git LFS & metadata
Đồng thời push repo `veo_version` để hệ thống electron-updater tự động nhận diện:
```powershell
cd "c:\Users\nguye\OneDrive\文档\veo_version"
git add latest.yml Veo3-Tho-va-nhim-Setup-*.exe*
git commit -m "release: v1.0.2"
git push origin main
git lfs push --all origin main
```
*(Lưu ý: Luôn chạy `git lfs push --all origin main` nếu thêm binary mới vào git).*

---

### 🔹 BƯỚC 5: Nghiệm Thu & Kiểm Tra (Verification)

1. **Kiểm tra Link tải:**
   Mở trình duyệt ở chế độ ẩn danh (Incognito) hoặc chạy lệnh test:
   ```powershell
   curl -I "https://github.com/nguyenzuanthuy/veo_version/releases/download/v1.0.2/Veo3-Tho-va-nhim-Setup-1.0.2.exe"
   ```
   *(Phải nhận được HTTP 302 chuyển tiếp đến file tải hoặc HTTP 200).*

2. **Kiểm tra Auto-Update trên Tool máy khách:**
   - Mở ứng dụng Veo3 bản cũ (v1.0.0 hoặc v1.0.1).
   - Góc trái bên dưới phải hiện thông báo: `v1.0.0 Bản v1.0.2 [Cập nhật]`.
   - Nhấn nút **Cập nhật** ➜ Phần trăm tải chạy từ `0%` ➜ `100%` ➜ App tự khởi động lại và nâng cấp lên `v1.0.2`.
