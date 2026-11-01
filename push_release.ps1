param(
    [string]$Version = "",
    [switch]$SkipLfs = $false
)

# Lấy version từ package.json nếu không truyền vào
if (-not $Version) {
    if (Test-Path 'package.json') {
        $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json
        $Version = $pkg.version
    } elseif (Test-Path "$PSScriptRoot\..\package.json") {
        $pkg = Get-Content "$PSScriptRoot\..\package.json" -Raw | ConvertFrom-Json
        $Version = $pkg.version
    } else {
        Write-Host "❌ Không xác định được số phiên bản!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "🚀 Bắt đầu quy trình phát hành tự động cho phiên bản v$Version..." -ForegroundColor Cyan

# Xác định thư mục veo_version
$veoVersionDir = (Resolve-Path "$PSScriptRoot\..\..\veo_version" -ErrorAction SilentlyContinue).Path
if (-not $veoVersionDir -or -not (Test-Path $veoVersionDir)) {
    # Nếu chạy trực tiếp từ trong veo_version
    if (Test-Path "$PSScriptRoot\.git") {
        $veoVersionDir = (Resolve-Path "$PSScriptRoot").Path
    } else {
        Write-Host "❌ Không tìm thấy thư mục veo_version!" -ForegroundColor Red
        exit 1
    }
}

Push-Location $veoVersionDir
try {
    Write-Host "📂 Đang làm việc tại: $veoVersionDir"

    # 1. Tự động xóa sạch file của các phiên bản cũ (chỉ giữ bản $Version mới)
    Get-ChildItem -Filter "Veo3-Tho-va-nhim-Setup-*.exe*" | Where-Object {
        $_.Name -notmatch [regex]::Escape($Version)
    } | ForEach-Object {
        Write-Host "🗑️ Đã xóa file phiên bản cũ: $($_.Name)" -ForegroundColor Yellow
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }

    # 2. Stage tất cả thay đổi (vừa nhận diện bản mới, vừa ghi nhận xóa bản cũ)
    git add -A

    # 3. Kiểm tra xem có thay đổi gì cần commit không
    $status = git status --porcelain
    if ($status) {
        git commit -m "release: v$Version - update installer and remove old versions"
        Write-Host "✅ Đã commit bản v$Version và loại bỏ bản cũ." -ForegroundColor Green
    } else {
        Write-Host "ℹ️ Không có thay đổi nào cần commit thêm." -ForegroundColor Gray
    }

    # 4. Push code lên nhánh main của veo_version
    Write-Host "🚀 Đang push lên GitHub repo veo_version (origin/main)..." -ForegroundColor Cyan
    git push origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Push origin main thất bại!" -ForegroundColor Red
        exit $LASTEXITCODE
    }

    # 5. Push file binary qua Git LFS
    if (-not $SkipLfs) {
        Write-Host "🚀 Đang đẩy binary dung lượng lớn qua Git LFS (git lfs push)..." -ForegroundColor Cyan
        git lfs push --all origin main
    }

    # 6. Gắn tag Git cho phiên bản mới
    git tag -a "v$Version" -m "Release v$Version" -f
    git push origin "v$Version" -f
    Write-Host "✅ Đã cập nhật Git Tag: v$Version" -ForegroundColor Green

    Write-Host ""
    Write-Host "🎉 HOÀN TẤT 100%! Bản mới v$Version đã được push và bản cũ đã được dọn sạch." -ForegroundColor Green
} finally {
    Pop-Location
}
