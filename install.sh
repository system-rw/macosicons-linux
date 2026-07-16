#!/usr/bin/env bash
set -e

echo "🍏 Installing macOSicons (CLI & GUI) for Linux..."

# Create local directories if they don't exist
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/share/icons

# Copy scripts to local path
ln cli/apply-mac-icon ~/.local/bin/
ln gui/apply-mac-icon-gui ~/.local/bin/
chmod +x cli/apply-mac-icon

# Copy the custom icons to the system's local icon folder
if [ -f assets/macosicons.png ]; then
  cp assets/macosicons.png ~/.local/share/icons/macosicons.png
fi
if [ -f assets/macosicons-gui.png ]; then
  cp assets/macosicons-gui.png ~/.local/share/icons/macosicons-gui.png
fi

# Copy and install BOTH .desktop launchers (CLI & GUI)
if [ -f cli/macosicons.desktop ]; then
  cp cli/macosicons.desktop ~/.local/share/applications/
fi
if [ -f gui/macosicons-gui.desktop ]; then
  cp gui/macosicons-gui.desktop ~/.local/share/applications/
fi

# Force KDE to rebuild its application database so they show up instantly
if command -v kbuildsycoca6 &>/dev/null; then
  kbuildsycoca6 --noincremental
elif command -v kbuildsycoca5 &>/dev/null; then
  kbuildsycoca5 --noincremental
fi

echo "✅ Done! You can now run your tools from your terminal or launch them from your app menu."
