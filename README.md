# Instructions: Install Autodesk Fusion 360 on Bazzite

> [!IMPORTANT]
> **Browser Warning:** Firefox installed via Flatpak or Snap has major issues with MIME handoffs. Use a browser installed directly from a distro repo (RPM/Binary) or a local binary extraction.

## 1. Quick Install (Recommended)

This method automates the Samba shims, the Bazzite-specific patching, and the Authentication Bridge setup.

### A. Standard Installation

Installs to the default path: `~/.local/opt/autodesk_fusion`

```bash
curl -sL https://raw.githubusercontent.com/robojerk/Autodesk-Fusion-360-for-Bazzite/main/install.sh | bash

```

### B. Full Installation (All Extensions)

Includes the heavy extension packs and extra components.

```bash
curl -sL https://raw.githubusercontent.com/robojerk/Autodesk-Fusion-360-for-Bazzite/main/install.sh | bash -s -- "" --full

```

### C. Custom Path Installation

If you want to install to a specific drive or folder:

```bash
# Syntax: bash -s -- "/your/custom/path" [--full]
curl -sL https://raw.githubusercontent.com/robojerk/Autodesk-Fusion-360-for-Bazzite/main/install.sh | bash -s -- "/home/rob/Games/fusion360" --full

```

---

## 2. Authentication (Login)

After the script finishes, launch Fusion 360. When you click **Sign In**:

1. Your browser will open the Autodesk login page.
2. Log in as usual.
3. Your browser should ask to open the link with **Autodesk Identity Manager**.
4. If you are using a local Firefox binary, it should hand off to the bridge script automatically and log you into the app.

**If the handoff fails:**
Copy the `adskidmgr://` link from your browser's address bar and run:

```bash
~/.local/bin/adskidmgr-handler "PASTE_LINK_HERE"

```

---

## 3. Launching & Performance Fixes

To prevent the application from freezing at startup and resolve `DXGI` rendering errors, you must force XWayland and disable specific GPU acceleration for the UI.

**Launch Command:**

```bash
# Force cleanup of ghost processes
wineserver -k

# Launch with Wayland disabled and GPU UI disabled
env WAYLAND_DISPLAY="" \
"$HOME/.local/opt/autodesk_fusion/bin/autodesk_fusion_launcher.sh" \
--disable-gpu --disable-software-rasterizer

```

---

## 4. Troubleshooting

### OctoPrint / CAM Errors

If the app loads but displays a Python Traceback error regarding `failed to find product`, the OctoPrint plugin is likely conflicting with the initialization. The install script attempts to rename this automatically, but you can do it manually:

```bash
# Replace <INSTALL_DIR> with your actual path
mv "<INSTALL_DIR>/wineprefixes/default/drive_c/users/$USER/AppData/Roaming/Autodesk/ApplicationPlugins/OctoPrint_for_Fusion360.bundle" \
   "<INSTALL_DIR>/wineprefixes/default/drive_c/users/$USER/AppData/Roaming/Autodesk/ApplicationPlugins/OctoPrint_for_Fusion360.bundle.bak"

```

### DXVK vs OpenGL

By default, this setup uses the **OpenGL fallback** on Intel/integrated GPUs to ensure stability. If you want to try for higher performance with DXVK, run the toggle script included in the bin folder:

```bash
"<INSTALL_DIR>/bin/fix-navbar-flicker.sh"

```
