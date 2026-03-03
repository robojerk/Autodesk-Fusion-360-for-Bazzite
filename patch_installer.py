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
