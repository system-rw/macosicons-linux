#!/usr/bin/env bash
set -e

INSTALL_DIR="$HOME/.local/bin"
REPO_URL="https://raw.githubusercontent.com/system-rw/macosicons-linux/main"
LOCAL_VERSION_FILE="$HOME/.config/macOSicons/VERSION"
REMOTE_VERSION=$(curl -sf "$REPO_URL/VERSION" 2>/dev/null | tr -d '[:space:]')

# ── Check for updates ────────────────────────────────────────────────────
check_update() {
    [ -z "$REMOTE_VERSION" ] && return
    if [ -f "$LOCAL_VERSION_FILE" ]; then
        LOCAL_VERSION=$(cat "$LOCAL_VERSION_FILE" | tr -d '[:space:]')
        if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
            echo ""
            echo "⬆️  Update available: $LOCAL_VERSION → $REMOTE_VERSION"
            echo "   Run ./install.sh --update to get the latest version."
            echo ""
        fi
    fi
}

# ── Update mode ──────────────────────────────────────────────────────────
if [ "${1:-}" = "--update" ]; then
    echo "🔄 Updating macOSicons..."
    if [ -d .git ]; then
        git pull --rebase 2>/dev/null || { echo "❌ git pull failed — are you in the repo directory?"; exit 1; }
    else
        echo "📥 Downloading latest files..."
        curl -sfL "$REPO_URL/cli/apply-mac-icon" -o cli/apply-mac-icon || { echo "❌ Download failed."; exit 1; }
        curl -sfL "$REPO_URL/gui/apply-mac-icon-gui" -o gui/apply-mac-icon-gui
        curl -sfL "$REPO_URL/install.sh" -o install.sh
        curl -sfL "$REPO_URL/VERSION" -o VERSION
    fi
    echo "📦 Installing updated files..."
    mkdir -p "$INSTALL_DIR" ~/.local/share/applications ~/.local/share/icons
    ln -f cli/apply-mac-icon "$INSTALL_DIR/apply-mac-icon"
    ln -f gui/apply-mac-icon-gui "$INSTALL_DIR/apply-mac-icon-gui"
    chmod +x "$INSTALL_DIR/apply-mac-icon"*
    [ -f assets/macosicons.png ] && cp assets/macosicons.png ~/.local/share/icons/macosicons.png
    [ -f assets/macosicons-gui.png ] && cp assets/macosicons-gui.png ~/.local/share/icons/macosicons-gui.png
    cp cli/macosicons.desktop ~/.local/share/applications/ 2>/dev/null
    cp gui/macosicons-gui.desktop ~/.local/share/applications/ 2>/dev/null
    mkdir -p "$(dirname "$LOCAL_VERSION_FILE")"
    [ -f VERSION ] && cp VERSION "$LOCAL_VERSION_FILE"
    echo "✅ Updated to $REMOTE_VERSION"
    exit 0
fi

echo "🍏 Installing macOSicons (CLI & GUI) for Linux..."

# Check for updates silently
check_update

# Check and install dependencies
install_deps() {
    # Detect distro
    if command -v pacman &>/dev/null; then
        PKG="pacman"
        SUDO="sudo pacman -S --noconfirm"
        pkg_names() { echo "$@"; }
    elif command -v apt &>/dev/null; then
        PKG="apt"
        SUDO="sudo apt install -y"
        pkg_names() { echo "$@"; }
    elif command -v dnf &>/dev/null; then
        PKG="dnf"
        SUDO="sudo dnf install -y"
        pkg_names() { echo "$@"; }
    elif command -v zypper &>/dev/null; then
        PKG="zypper"
        SUDO="sudo zypper install -y"
        pkg_names() { echo "$@"; }
    else
        echo "⚠️  Could not detect package manager. Install manually:"
        echo "   python3, python3-pyqt6, icnsutils, imagemagick, kdialog, fzf"
        read -rp "Continue anyway? [y/N] " yn
        [[ "$yn" =~ ^[Yy]$ ]] || exit 1
        return
    fi

    NEED_SYS=()
    NEED_PIP=()

    command -v python3 &>/dev/null || NEED_SYS+=("python3")
    python3 -c "import PyQt6" 2>/dev/null || NEED_PIP+=("PyQt6")
    command -v icns2png &>/dev/null || NEED_SYS+=("icnsutils")
    command -v magick &>/dev/null || NEED_SYS+=("imagemagick")
    command -v kdialog &>/dev/null || NEED_SYS+=("kdialog")
    command -v fzf &>/dev/null || NEED_SYS+=("fzf")

    if [ ${#NEED_SYS[@]} -eq 0 ] && [ ${#NEED_PIP[@]} -eq 0 ]; then
        echo "✅ All dependencies satisfied."
        return
    fi

    echo "📦 Installing missing dependencies..."
    if [ ${#NEED_SYS[@]} -gt 0 ]; then
        echo "   $PKG: ${NEED_SYS[*]}"
        $SUDO $(pkg_names "${NEED_SYS[@]}")
    fi
    if [ ${#NEED_PIP[@]} -gt 0 ]; then
        echo "   pip: ${NEED_PIP[*]}"
        pip install "${NEED_PIP[@]}"
    fi
    echo "✅ Dependencies installed."
}

install_deps

# Create local directories if they don't exist
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/applications
mkdir -p ~/.local/share/icons

# Copy scripts to local path
ln cli/apply-mac-icon ~/.local/bin/
ln gui/apply-mac-icon-gui ~/.local/bin/
chmod +x ~/.local/bin/apply-mac-icon*

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
if command -v kbuildsycoca6 &> /dev/null; then
    kbuildsycoca6 --noincremental
elif command -v kbuildsycoca5 &> /dev/null; then
    kbuildsycoca5 --noincremental
fi

mkdir -p "$(dirname "$LOCAL_VERSION_FILE")"
[ -f VERSION ] && cp VERSION "$LOCAL_VERSION_FILE"

echo "✅ Done! You can now run your tools from your terminal or launch them from your app menu."
