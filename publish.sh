#!/bin/bash
set -euo pipefail

REPO="kim370485-png/customer-service-plugin"
RAW_BASE="https://raw.githubusercontent.com/$REPO/main"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error() { echo -e "${RED}✗ $1${NC}" >&2; exit 1; }
ok()    { echo -e "${GREEN}✓ $1${NC}"; }
info()  { echo -e "${YELLOW}→ $1${NC}"; }

# ── 前置检查 ──────────────────────────────────────────────

if [ ! -d "src" ] || [ ! -f "src/manifest.json" ]; then
  error "src/manifest.json 不存在，请把插件源码放到 src/ 目录"
fi

# ── 版本号 ────────────────────────────────────────────────

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  if command -v python3 >/dev/null 2>&1; then
    VERSION=$(python3 -c "import json; print(json.load(open('src/manifest.json'))['version'])")
  elif command -v node >/dev/null 2>&1; then
    VERSION=$(node -e "console.log(require('./src/manifest.json').version)")
  else
    error "请传入版本号: ./publish.sh 5.4"
  fi
  info "从 manifest.json 读取版本: $VERSION"
fi

# 同步 manifest.json 版本号（确保 .crx 和 updates.xml 版本一致）
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|\"version\": \"[0-9][0-9.]*\"|\"version\": \"$VERSION\"|" src/manifest.json
else
  sed -i "s|\"version\": \"[0-9][0-9.]*\"|\"version\": \"$VERSION\"|" src/manifest.json
fi

# ── 打包 .crx ─────────────────────────────────────────────

# 使用 Python 打包 CRX3（Chrome --pack-extension 在部分系统上不使用指定 key）
if [ ! -f "key.pem" ]; then
  error "key.pem 不存在！需要私钥文件来签名扩展"
fi

info "使用 Python 打包 CRX3..."
python3 << 'PYEOF'
import struct, hashlib, zipfile, io, os, subprocess, sys

def encode_varint(value):
    result = b''
    while value > 0x7f:
        result += bytes([(value & 0x7f) | 0x80])
        value >>= 7
    result += bytes([value & 0x7f])
    return result

def encode_field(field_num, wire_type, data):
    tag = (field_num << 3) | wire_type
    if wire_type == 2:
        return encode_varint(tag) + encode_varint(len(data)) + data
    elif wire_type == 0:
        return encode_varint(tag) + encode_varint(data)
    else:
        raise ValueError(f"Unsupported wire type: {wire_type}")

# Create ZIP
zip_buffer = io.BytesIO()
with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk('src'):
        for file in files:
            filepath = os.path.join(root, file)
            arcname = os.path.relpath(filepath, 'src')
            zf.write(filepath, arcname)
zip_data = zip_buffer.getvalue()

# Load keys
with open('key.pem', 'rb') as f:
    key_pem = f.read()

result = subprocess.run(['openssl', 'rsa', '-in', 'key.pem', '-pubout', '-outform', 'DER'], capture_output=True)
if result.returncode != 0:
    print("Error: Failed to extract public key from key.pem", file=sys.stderr)
    sys.exit(1)
pub_key_der = result.stdout

try:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import padding
    from cryptography.hazmat.backends import default_backend
except ImportError:
    print("Error: cryptography library not installed. Run: pip3 install cryptography", file=sys.stderr)
    sys.exit(1)

private_key = serialization.load_pem_private_key(key_pem, password=None, backend=default_backend())

# Create placeholder SignedData for signing
placeholder_sig = b'\x00' * 256
signed_data_fields = encode_field(1, 2, placeholder_sig) + encode_field(2, 2, pub_key_der)
crx_header = encode_field(2, 2, signed_data_fields)

# Sign: "CRX3 SignedData\x00" + header + zip
signed_content = b'CRX3 SignedData\x00' + crx_header + zip_data
signature = private_key.sign(signed_content, padding.PKCS1v15(), hashes.SHA256())

# Create final SignedData with real signature
signed_data_fields = encode_field(1, 2, signature) + encode_field(2, 2, pub_key_der)
crx_header = encode_field(2, 2, signed_data_fields)

# Build CRX3 file
crx = b'Cr24' + struct.pack('<I', 3) + struct.pack('<I', len(crx_header)) + crx_header + zip_data

os.makedirs('build', exist_ok=True)
with open('build/extension.crx', 'wb') as f:
    f.write(crx)

# Verify ID
header_size = struct.unpack('<I', crx[8:12])[0]
header = crx[12:12+header_size]

def parse_pb(data):
    pos = 0; fields = []
    while pos < len(data):
        byte = data[pos]; fn = byte >> 3; wt = byte & 0x07; pos += 1
        if wt == 2:
            l, s = 0, 0
            while pos < len(data):
                b = data[pos]; l |= (b & 0x7f) << s; pos += 1
                if not (b & 0x80): break
                s += 7
            val = data[pos:pos+l]; pos += l
            fields.append((fn, val))
        elif wt == 0:
            val, s = 0, 0
            while pos < len(data):
                b = data[pos]; val |= (b & 0x7f) << s; pos += 1
                if not (b & 0x80): break
                s += 7
            fields.append((fn, val))
        else: break
    return fields

for fn, fv in parse_pb(header):
    if fn == 2 and isinstance(fv, bytes):
        for sfn, sfv in parse_pb(fv):
            if sfn == 2 and isinstance(sfv, bytes):
                h = hashlib.sha256(sfv).hexdigest()[:32]
                ext_id = ''.join(chr(ord('a') + int(c, 16)) for c in h)
                print(f"  CRX Extension ID: {ext_id}")

print(f"  CRX size: {len(crx)} bytes")
PYEOF

if [ -f "build/extension.crx" ]; then
  ok "打包完成: build/extension.crx"
else
  error "Python 打包失败"
fi

# ── 更新 updates.xml ──────────────────────────────────────

# .crx 直接提交到仓库，URL 固定为 raw.githubusercontent.com
CODEBASE_URL="$RAW_BASE/extension.crx"

if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|version='[0-9][0-9.]*' />|version='$VERSION' />|" updates.xml
else
  sed -i "s|version='[0-9][0-9.]*' />|version='$VERSION' />|" updates.xml
fi
ok "updates.xml 已更新 → version=$VERSION"

# ── 提交推送 ──────────────────────────────────────────────

cp build/extension.crx extension.crx

git add updates.xml extension.crx src/manifest.json
git commit -m "chore: bump to v$VERSION" 2>/dev/null || true
git push origin main
ok "已推送到 GitHub"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  v$VERSION 发布完成！${NC}"
echo -e "${GREEN}  同事的 Chrome 会在下次检查更新时自动升级${NC}"
echo -e "${GREEN}  手动触发: chrome://extensions → 刷新按钮${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
