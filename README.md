# Instructions: Install Autodesk Fusion 360 on Bazzite

> [!IMPORTANT]
> **Browser Warning:** Firefox installed via Flatpak or Snap has significant issues with MIME handoffs. Use a browser installed directly from a distro repo (RPM/Binary) or a local binary extraction.

## 1. Prerequisites (Samba Shim)

The installer expects a `samba` command. Since Bazzite is immutable and Homebrew's version uses `smbd`, create this shim to pass the dependency check:

```bash
mkdir -p ~/.local/bin
cat > ~/.local/bin/samba << 'EOF'
#!/bin/bash
exec smbd "$@" 2>/dev/null || true
EOF
chmod +x ~/.local/bin/samba
export PATH="$HOME/.local/bin:$PATH"

```

## 2. Get and Patch the Installer

Download the script and use the Python patcher below to bypass package manager calls and fix `mokutil` detection.

```bash
curl -L https://codeberg.org/cryinkfly/Autodesk-Fusion-360-on-Linux/raw/branch/main/files/setup/autodesk_fusion_installer_x86-64.sh -o "autodesk_fusion_installer_x86-64.sh"
chmod +x autodesk_fusion_installer_x86-64.sh

```

### Create `patch_installer.py`

```python
#!/usr/bin/env python3
import re

with open("autodesk_fusion_installer_x86-64.sh", "r") as f:
    content = f.read()

# Fix 1: Add Bazzite to the Fedora/Nobara check
content = content.replace('$DISTRO_VERSION == *"fedora"* ]] || [[ $DISTRO_VERSION == *"nobara"* ]]; then', 
                          '$DISTRO_VERSION == *"fedora"* ]] || [[ $DISTRO_VERSION == *"nobara"* ]] || [[ $DISTRO_VERSION == *"bazzite"* ]]; then')

# Fix 2: Add Bazzite to the Wine install check
content = content.replace('$DISTRO_VERSION == *"Fedora"* && $DISTRO_VERSION == *"43"* ]] || [[ $DISTRO_VERSION == *"Nobara"* ]]; then', 
                          '$DISTRO_VERSION == *"Fedora"* && $DISTRO_VERSION == *"43"* ]] || [[ $DISTRO_VERSION == *"Nobara"* ]] || [[ $DISTRO_VERSION == *"Bazzite"* ]]; then')

# Fix 3: DISABLE the package check function entirely to prevent dnf/sudo errors
content = re.sub(r'check_required_packages\(\) \{.*?\n\}', 
                 'check_required_packages() {\n    return 0\n}', 
                 content, flags=re.DOTALL)

# Fix 4: Fix mokutil detection (Check for binary existence only)
content = content.replace('if ! mokutil --list-enrolled &>/dev/null; then', 
                          'if ! command -v mokutil &>/dev/null; then')

with open("autodesk_fusion_installer_x86-64.sh", "w") as f:
    f.write(content)

print("Successfully patched installer: Package checks disabled and mokutil fixed.")

```

**Run:** `python3 patch_installer.py`

## 3. Run the Installation

Pre-create the directory to satisfy the installer's disk space check.

```bash
mkdir -p "$HOME/.local/opt/autodesk_fusion"
./autodesk_fusion_installer_x86-64.sh --install "$HOME/.local/opt/autodesk_fusion" --full

```

## 4. Fix Authentication (URI Scheme)

The login callback uses `adskidmgr://`. We use a bridge script to ensure Wine handles the request directly.

### Step A: Create the Bridge Script

Find your specific production hash first: `find "$HOME/.local/opt/autodesk_fusion" -name "AdskIdentityManager.exe"` and update the path below if it differs.

```bash
cat > ~/.local/bin/adskidmgr-handler << 'EOF'
#!/bin/bash
WINEPREFIX="/home/rob/.local/opt/autodesk_fusion/wineprefixes/default" \
/home/rob/.local/bin/wine \
"C:\\Program Files\\Autodesk\\webdeploy\\production\\10477bbe50cc169c7bd2cee9059bc7c9d0b71ec0\\Autodesk Identity Manager\\AdskIdentityManager.exe" "$1"
EOF
chmod +x ~/.local/bin/adskidmgr-handler

```

### Step B: Register the Desktop Entry

```bash
cat > ~/.local/share/applications/adsk-identity-manager.desktop << EOF
[Desktop Entry]
Name=Autodesk Identity Manager
Exec=/home/rob/.local/bin/adskidmgr-handler %u
Type=Application
MimeType=x-scheme-handler/adskidmgr;
X-KDE-Protocols=adskidmgr
EOF

xdg-mime default adsk-identity-manager.desktop x-scheme-handler/adskidmgr
update-desktop-database ~/.local/share/applications/

```

## 5. Launching and Resolving Freezes

To prevent UI freezes and `DXGI` rendering errors, force XWayland and disable hardware acceleration for the UI overlays.

```bash
# 1. Clear any stuck Wine processes
wineserver -k

# 2. Disable OctoPrint plugin if it causes CAM product errors
PLUGIN_DIR="$HOME/.local/opt/autodesk_fusion/wineprefixes/default/drive_c/users/rob/AppData/Roaming/Autodesk/ApplicationPlugins"
if [ -d "$PLUGIN_DIR/OctoPrint_for_Fusion360.bundle" ]; then
    mv "$PLUGIN_DIR/OctoPrint_for_Fusion360.bundle" "$PLUGIN_DIR/OctoPrint_for_Fusion360.bundle.bak"
fi

# 3. Launch with XWayland and GPU UI disabled
env WAYLAND_DISPLAY="" \
"$HOME/.local/opt/autodesk_fusion/bin/autodesk_fusion_launcher.sh" \
--disable-gpu --disable-software-rasterizer

```
