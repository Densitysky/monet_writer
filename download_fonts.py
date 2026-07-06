"""Download 16 LXGW free fonts from GitHub releases for the Monet Writer project."""
import os, json, urllib.request, urllib.error, time

FONTS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fonts")
os.makedirs(FONTS_DIR, exist_ok=True)

# 16 fonts: (display_name, github_repo, preferred_filename)
FONTS = [
    ("霞鹜新晰黑",     "lxgw/LxgwNeoXiHei",     "LXGWNeoXiHei"),
    ("悠哉字体",       "lxgw/yozai-font",        "LXGWYozai"),
    ("霞鹜文楷",       "lxgw/LxgwWenKai",        "LXGWWenKai"),
    ("霞鹜新致宋",     "lxgw/LxgwNeoZhiSong",    "LXGWNeoZhiSong"),
    ("彭蠡文楷",       "lxgw/Pengli",            "LXGWPengliWenKai"),
    ("霞鹜铭心宋",     "lxgw/LxgwHeartSerif",    "LXGWHeartSerif"),
    ("霞鹜致宋",       "lxgw/LxgwZhiSong",       "LXGWZhiSong"),
    ("霞鹜文楷GB",     "lxgw/LxgwWenkaiGB",      "LXGWWenKaiGB"),
    ("霞鹜文楷TC",     "lxgw/LxgwWenkaiTC",      "LXGWWenKaiTC"),
    ("霞鹜臻楷",       "lxgw/LxgwZhenKai",       "LXGWZhenKai"),
    ("霞鹜尚智黑",     "lxgw/LxgwFasmartGothic",  "LXGWFasmartGothic"),
    ("霞鹜漫黑",       "lxgw/LxgwMarkerGothic",  "LXGWMarkerGothic"),
    ("霞鹜975朦胧黑体","lxgw/975HazyGo",         "LXGW975HazyGo"),
    ("975圆体",        "lxgw/975Yuan",           "LXGW975Yuan"),
    ("霞鹜975黑体",    "lxgw/975Hei",            "LXGW975Hei"),
    ("小赖字体",       "lxgw/kose-font",         "LXGWXiaoLai"),
]

def fetch_latest_release(repo):
    """Fetch latest release info from GitHub API."""
    url = f"https://api.github.com/repos/{repo}/releases/latest"
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "MonetWriter/1.0"}
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        print(f"  ⚠ HTTP {e.code} for {repo}")
        return None
    except Exception as e:
        print(f"  ⚠ Error: {e}")
        return None

def download_file(url, dest):
    """Download a file from url to dest path."""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "MonetWriter/1.0"})
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = resp.read()
            with open(dest, "wb") as f:
                f.write(data)
            return len(data)
    except Exception as e:
        print(f"    ✗ Download failed: {e}")
        return 0

def find_ttf_assets(release_data):
    """Find all TTF/TTC assets in a GitHub release."""
    assets = []
    for asset in release_data.get("assets", []):
        name = asset.get("name", "")
        if name.lower().endswith((".ttf", ".ttc", ".otf")):
            # Skip sources, scripts, etc.
            skip_keywords = ["source", "script", "webfont", "doc", "example"]
            if any(kw in name.lower() for kw in skip_keywords):
                continue
            assets.append((name, asset["browser_download_url"]))
    return assets

def main():
    total_downloaded = 0
    total_size = 0
    failed = []

    for display_name, repo, preferred_name in FONTS:
        print(f"\n[{display_name}] {repo}")
        release = fetch_latest_release(repo)

        if not release:
            failed.append(display_name)
            continue

        tag = release.get("tag_name", "unknown")
        print(f"  Tag: {tag}")

        ttf_assets = find_ttf_assets(release)
        if not ttf_assets:
            print(f"  ⚠ No TTF assets found in release")
            # Try downloading from tag directly (common pattern)
            alt_url = f"https://github.com/{repo}/releases/download/{tag}/{preferred_name}.ttf"
            print(f"  Trying direct URL: {alt_url}")
            dest = os.path.join(FONTS_DIR, f"{preferred_name}.ttf")
            if os.path.exists(dest):
                print(f"  ✓ Already exists, skipping")
                continue
            size = download_file(alt_url, dest)
            if size > 1000:  # at least 1KB
                total_downloaded += 1
                total_size += size
                print(f"  ✓ Downloaded {preferred_name}.ttf ({size/1024:.0f} KB)")
            else:
                failed.append(display_name)
            continue

        for asset_name, asset_url in ttf_assets:
            ext = os.path.splitext(asset_name)[1]  # .ttf or .ttc or .otf
            # Use display-name-based filename
            safe_name = preferred_name + ext
            # Check if this is a "plus" variant (with more characters)
            if "plus" in asset_name.lower() or "bold" in asset_name.lower():
                safe_name = preferred_name + "-" + asset_name.split(".")[0].split("-")[-1] + ext

            dest = os.path.join(FONTS_DIR, safe_name)
            if os.path.exists(dest):
                existing = os.path.getsize(dest)
                print(f"  · {safe_name} already exists ({existing/1024:.0f} KB), skipping")
                total_downloaded += 1
                total_size += existing
                continue

            print(f"  ↓ {asset_name} ...", end=" ")
            size = download_file(asset_url, dest)
            if size > 1000:
                total_downloaded += 1
                total_size += size
                print(f"({size/1024:.0f} KB) ✓")
            else:
                print("✗")
                if display_name not in failed:
                    failed.append(display_name)

        time.sleep(0.5)  # Rate limit

    # Summary
    print(f"\n{'='*50}")
    print(f"Download complete!")
    print(f"  Success: {total_downloaded} files")
    print(f"  Total size: {total_size/1024/1024:.1f} MB")
    if failed:
        print(f"  Failed: {', '.join(failed)}")

    # List fonts directory
    print(f"\nFonts directory ({FONTS_DIR}):")
    for f in sorted(os.listdir(FONTS_DIR)):
        path = os.path.join(FONTS_DIR, f)
        size = os.path.getsize(path)
        print(f"  {f:40s} {size/1024:8.0f} KB")

if __name__ == "__main__":
    main()
