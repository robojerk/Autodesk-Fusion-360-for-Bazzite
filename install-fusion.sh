#!/bin/bash
set -e

# --- 1. HANDLE ARGUMENTS ---
# Default to $HOME/.local/opt/autodesk_fusion if no path is provided
CUSTOM_PATH=$1
INSTALL_DIR="${CUSTOM_PATH:-$HOME/.local/opt/autodesk_fusion}"

# Shift the arguments so we can check for --full separately
shift $(( ${#CUSTOM_PATH} > 0 ? 1 : 0 ))

# Determine if --full was passed
INSTALL_ARGS="--install $INSTALL_DIR"
if [[ "$*" == *"--full"* ]]; then
    INSTALL_ARGS="$INSTALL_ARGS --full"
    echo "--- Full installation requested ---"
else
    echo "--- Standard installation requested ---"
fi

echo "--- Installing to: $INSTALL_DIR ---"

# --- 2. SETUP ENVIRONMENT ---
LOCAL_BIN="$HOME/.local/bin"
WINE_PREFIX="$INSTALL_DIR/wineprefixes/default"
WINE_BIN="$LOCAL_BIN/wine"

mkdir -p "$LOCAL_BIN"
cat > "$LOCAL_BIN/samba" << 'EOF'
#!/bin/bash
exec smbd "$@" 2>/dev/null || true
EOF
chmod +x "$LOCAL_BIN/samba"
export PATH="$LOCAL_BIN:$PATH"

# --- 3. DOWNLOAD & PATCH ---
echo "--- Downloading Installer and Bazzite Patcher ---"
curl -L https://codeberg.org/cryinkfly/Autodesk-Fusion-360-on-Linux/raw/branch/main/files/setup/autodesk_fusion_installer_x86-64.sh -o "autodesk_fusion_installer_x86-64.sh"
chmod +x autodesk_fusion_installer_x86-64.sh

curl -L https://raw.githubusercontent.com/robojerk/Autodesk-Fusion-360-for-Bazzite/refs/heads/main/patch_installer.py -o patch_installer.py
python3 patch_installer.py

# --- 4. EXECUTE INSTALLATION ---
mkdir -p "$INSTALL_DIR"
./autodesk_fusion_installer_x86-64.sh $INSTALL_ARGS

# --- 5. CONFIGURE AUTHENTICATION BRIDGE ---
echo "--- Configuring Authentication Bridge ---"
ID_MGR_EXE=$(find "$WINE_PREFIX" -name "AdskIdentityManager.exe" | head -n 1)

if [ -n "$ID_MGR_EXE" ]; then
    # Dynamic path conversion for Wine
    WINE_EXE_PATH="C:\\${ID_MGR_EXE#*drive_c/}"
    WINE_EXE_PATH=${WINE_EXE_PATH//\//\\}

    cat > "$LOCAL_BIN/adskidmgr-handler" << EOF
#!/bin/bash
WINEPREFIX="$WINE_PREFIX" "$WINE_BIN" "$WINE_EXE_PATH" "\$1"
EOF
    chmod +x "$LOCAL_BIN/adskidmgr-handler"

    cat > "$HOME/.local/share/applications/adsk-identity-manager.desktop" << EOF
[Desktop Entry]
Name=Autodesk Identity Manager
Exec=$LOCAL_BIN/adskidmgr-handler %u
Type=Application
MimeType=x-scheme-handler/adskidmgr;
X-KDE-Protocols=adskidmgr
Terminal=false
EOF
    xdg-mime default adsk-identity-manager.desktop x-scheme-handler/adskidmgr
    update-desktop-database "$HOME/.local/share/applications/"
fi

# --- 6. FLATPAK & PLUGIN FIXES ---
if flatpak list | grep -q "org.mozilla.firefox"; then
    flatpak override --user --talk-name=org.freedesktop.portal.Desktop org.mozilla.firefox
    flatpak override --user --filesystem=xdg-data/applications:ro org.mozilla.firefox
fi

PLUGIN_PATH="$WINE_PREFIX/drive_c/users/$USER/AppData/Roaming/Autodesk/ApplicationPlugins/OctoPrint_for_Fusion360.bundle"
[ -d "$PLUGIN_PATH" ] && mv "$PLUGIN_PATH" "${PLUGIN_PATH}.bak"

echo "--- INSTALLATION COMPLETE ---"
echo "Launch with: WAYLAND_DISPLAY=\"\" $INSTALL_DIR/bin/autodesk_fusion_launcher.sh --disable-gpu"
