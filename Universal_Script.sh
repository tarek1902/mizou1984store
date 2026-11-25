#!/bin/sh
# ============================================================
# All-Script V21 FAST - By Eng / Ahmed Abdel-Moati
# Copyright (c) 2026 Eng / Ahmed Abdel-Moati
# V20 + novalerdownloader Exact + SubExtractorLite FIXED
# Packages First + Fixed Plugins After Packages
# Retry 5 Times - Then SKIP - SubExtractorLite 6 URLs + IPK Fallback
# ============================================================
clear
P="/usr/script/allscript_progress.txt"
mkdir -p /usr/script
touch "$P"; DONE=$(cat "$P" 2>/dev/null); [ -z "$DONE" ] && DONE=0
START_ALL=$(date +%s)

# ============================================================
# اولا - منع اي ريستارت للجهاز نهائيا بكل الطرق
# لحد امر SubExtractorLite وبعد نهايته
# ============================================================
mkdir -p /tmp/noreboot
for c in reboot shutdown halt poweroff; do
  printf '#!/bin/sh\nexit 0\n' > /tmp/noreboot/$c; chmod 755 /tmp/noreboot/$c
done
for c in mke2fs mkfs mkfs.vfat mkfs.ext4 mkfs.ext3 mkfs.fat fdisk sfdisk parted; do
  printf '#!/bin/sh\necho "[BLOCKED] %s - Formatting Disabled"\nexit 1\n' "$c" > /tmp/noreboot/$c; chmod 755 /tmp/noreboot/$c
done
printf '#!/bin/sh\necho "N 3"\nexit 0\n' > /tmp/noreboot/runlevel; chmod 755 /tmp/noreboot/runlevel
cat > /tmp/noreboot/init << 'EOF'
#!/bin/sh
case "$1" in
  0|6|reboot|poweroff|halt) echo "[BLOCKED] init $1 - Anti-Reboot Active Until SubExtractorLite Done"; exit 0 ;;
  3|4|5|q|Q|u|U|"") exit 0 ;;
  *) exit 0 ;;
esac
EOF
chmod 755 /tmp/noreboot/init
cp /tmp/noreboot/init /tmp/noreboot/telinit
cat > /tmp/noreboot/systemctl << 'EOF'
#!/bin/sh
case "$*" in
  *reboot*|*poweroff*|*halt*|*restart*enigma2*) echo "[BLOCKED] systemctl $* - Anti-Reboot Active"; exit 0 ;;
  *is-active*|*is-enabled*|*status*) exit 0 ;;
  *) exit 0 ;;
esac
EOF
chmod 755 /tmp/noreboot/systemctl
cat > /tmp/noreboot/busybox << 'EOF'
#!/bin/sh
if [ "$1" = "reboot" ] || [ "$1" = "poweroff" ] || [ "$1" = "halt" ]; then echo "[BLOCKED] busybox $1"; exit 0; fi
exec /bin/busybox "$@"
EOF
chmod 755 /tmp/noreboot/busybox
printf '#!/bin/sh\nif echo "$@" | grep -qi "enigma2"; then echo "[BLOCKED] killall enigma2 - Anti-Reboot Active"; exit 0; fi\nexec /bin/killall "$@"\n' > /tmp/noreboot/killall
chmod 755 /tmp/noreboot/killall
O="$PATH"; export PATH="/tmp/noreboot:$PATH"

# ============================================================
# WAIT_NET سريع - ping مرة واحدة بس
# ============================================================
WAIT_NET() {
  while true; do
    ping -c1 -W2 8.8.8.8 >/dev/null 2>&1 && return 0
    echo "   [WAIT] No Internet - Waiting 5 sec..."
    sleep 5; export PATH="/tmp/noreboot:$PATH"
  done
}
W() { WAIT_NET; }
echo "Checking Internet..."
WAIT_NET
echo "Internet OK - Starting..."

# ============================================================
# ثانيا - كشف نوع الجهاز بكل الـ 27 مصدر
# ============================================================
DEV_RAW="$(cat /proc/stb/info/model 2>/dev/null; echo " "
cat /proc/stb/info/boxtype 2>/dev/null; echo " "
cat /proc/stb/info/chipset 2>/dev/null; echo " "
cat /proc/stb/info/board 2>/dev/null; echo " "
cat /proc/stb/info/hwrev 2>/dev/null; echo " "
cat /proc/stb/info/vfd 2>/dev/null; echo " "
cat /proc/stb/fp/version 2>/dev/null; echo " "
cat /proc/stb/ir/rc 2>/dev/null; echo " "
cat /proc/device-tree/model 2>/dev/null; echo " "
cat /proc/device-tree/compatible 2>/dev/null; echo " "
cat /proc/device-tree/serial-number 2>/dev/null; echo " "
cat /sys/firmware/devicetree/base/model 2>/dev/null; echo " "
cat /sys/firmware/devicetree/base/compatible 2>/dev/null; echo " "
cat /sys/class/dmi/id/product_name 2>/dev/null; echo " "
cat /etc/hostname 2>/dev/null; echo " "
cat /etc/machine 2>/dev/null; echo " "
cat /etc/boxtype 2>/dev/null; echo " "
cat /etc/model 2>/dev/null; echo " "
cat /etc/brand 2>/dev/null; echo " "
cat /proc/cpuinfo 2>/dev/null | grep -i "hardware\|model\|revision"; echo " "
cat /proc/cmdline 2>/dev/null; echo " "
cat /proc/mtd 2>/dev/null; echo " "
cat /proc/bus/input/devices 2>/dev/null | grep -i "name="; echo " "
uname -a 2>/dev/null; echo " "
uname -m 2>/dev/null; echo " "
opkg print-architecture 2>/dev/null; echo " "
lsusb 2>/dev/null; echo " "
cat /etc/enigma2/settings 2>/dev/null | grep -i "boxtype\|device\|model"
python3 -c "from Tools.HardwareInfo import HardwareInfo; print(HardwareInfo().get_device_name()); print(HardwareInfo().get_device_brand()); print(HardwareInfo().get_device_model())" 2>/dev/null
python -c "from Tools.HardwareInfo import HardwareInfo; print(HardwareInfo().get_device_name()); print(HardwareInfo().get_device_brand()); print(HardwareInfo().get_device_model())" 2>/dev/null
)"
DEV="$(echo "$DEV_RAW" | tr 'A-Z' 'a-z' | tr -d ' _-/.')"
echo "Device Raw: $DEV_RAW"
IS_NOVALER=0; IS_VU=0; IS_DREAM=0; IS_ZGEMMA=0; IS_OCTAGON=0; IS_GIGABLUE=0; IS_UCLAN=0; IS_XTREND=0; IS_FORMULER=0
echo "$DEV" | grep -q "novaler\|novalerpro\|novaler4k\|novalerpro4k\|novalerhd" && IS_NOVALER=1
echo "$DEV" | grep -q "vuplus\|vu+\|vuduo\|vuuno\|vuultimo\|vusolo\|vuzero\|vuduo2\|vuduo4k\|vuduo4kse\|vuuno4k\|vuuno4kse\|vuultimo4k\|vuzero4k\|vusolo4k\|vusolo2\|vusolose" && IS_VU=1
echo "$DEV" | grep -q "dreambox\|dreamos\|dream\|dm920\|dm900\|dm820\|dm7080\|dm520\|dm525\|dm800\|dm8000\|dm7020\|dm800se\|dm800hd\|dreamone\|dreamtwo\|dreamboxone\|dreamboxtwo" && IS_DREAM=1
echo "$DEV" | grep -q "zgemma\|h9\|h10\|h11\|h7\|h8\|h9s\|h9twin\|h92h\|h11s\|h9se\|h102h\|h7s\|h7c\|h8se\|h9combo\|h11combo\|h10combo" && IS_ZGEMMA=1
echo "$DEV" | grep -q "octagon\|sf8008\|sf8008m\|sf8008mini\|sf8008supreme\|sf4008\|sf5008\|sx88\|sx888\|sx88v2\|sf8008v2\|sf8008e2" && IS_OCTAGON=1
echo "$DEV" | grep -q "gigablue\|gbquad\|gbue4k\|gbtrio4k\|gbip4k\|gbquad4k\|gbquadplus" && IS_GIGABLUE=1
echo "$DEV" | grep -q "uclan\|ustym\|ustym4k\|ustym4kpro" && IS_UCLAN=1
echo "$DEV" | grep -q "xtrend\|et10000\|et11000\|et8500\|et8000\|et7000" && IS_XTREND=1
echo "$DEV" | grep -q "formuler\|f1\|f3\|f4\|f4turbo\|z8\|z10\|z11\|zalpha" && IS_FORMULER=1
IS_NOT_NOVALER=0; [ "$IS_NOVALER" = "0" ] && IS_NOT_NOVALER=1
echo "Detect: Novaler=$IS_NOVALER Vu=$IS_VU Dream=$IS_DREAM Zgemma=$IS_ZGEMMA Octagon=$IS_OCTAGON Gigablue=$IS_GIGABLUE Uclan=$IS_UCLAN Xtrend=$IS_XTREND Formuler=$IS_FORMULER"

# ============================================================
# كشف نوع البايثون
# ============================================================
if python --version 2>&1 | grep -q '^Python 3\.'; then PYTHON='PY3'; echo "You have Python3 image"; else PYTHON='PY2'; echo "You have Python2 image"; fi
PY3_VER="$(python3 --version 2>&1)"; PYV="$(python --version 2>&1 | grep -o "3\.[0-9]*\|2\.[0-9]*")"
[ -z "$PYV" ] && PYV=$(python3 --version 2>&1 | grep -o "3\.[0-9]*")
echo "Python Version: $PYV - Mode: $PYTHON"

# ============================================================
# رابعا - كشف نوع الصورة
# ============================================================
G() { cat /etc/image-version 2>/dev/null; echo ""; cat /etc/issue 2>/dev/null; echo ""; cat /etc/os-release 2>/dev/null; echo ""; cat /etc/version 2>/dev/null; echo ""; cat /etc/enigma2/settings 2>/dev/null | grep -i "image\|distro"; }
R="$(G)"
IS_ATV=0; IS_EGAMI=0; IS_PLI=0; IS_VIX=0; IS_BH=0
echo "$R" | grep -qi openatv && IS_ATV=1
echo "$R" | grep -qi egami && IS_EGAMI=1
echo "$R" | grep -qi openpli && IS_PLI=1
echo "$R" | grep -qi openvix && IS_VIX=1
echo "$R" | grep -qi "openbh\|blackhole" && IS_BH=1
echo "Image: ATV=$IS_ATV Egami=$IS_EGAMI PLi=$IS_PLI ViX=$IS_VIX BH=$IS_BH"

# ============================================================
# باك اب للضبط قبل اي حاجة
# ============================================================
mkdir -p /media/hdd/backup/before_allscript /tmp/backup_before_restore
cp -a /etc/enigma2/settings /media/hdd/backup/before_allscript/settings.bak 2>/dev/null
cp -a /etc/enigma2/settings /tmp/backup_before_restore/ 2>/dev/null
echo "Settings Backup Saved to /media/hdd/backup/before_allscript/settings.bak"

# ============================================================
# اوامر الباكدجات - يتم في الاول - سريع timeout 60
# ============================================================
is_installed() {
  grep -q "^Package: $1$" /var/lib/opkg/status 2>/dev/null && grep -q "^Status: install ok installed$" /var/lib/opkg/status 2>/dev/null
}
PACKAGESPY3="p7zip wget python3-requests python3-imaging python3-lxml python3-pycrypto python3-multiprocessing python3-pyexecjs python3-sqlite3 python3-six python3-codecs python3-compression python3-difflib python3-xmlrpc python3-html python3-misc python3-shell python3-twisted-web python3-unixadmin python3-compression python3-treq python3-json python3-cryptography python3-netclient python3-pyopenssl python3-futures3 python3-beautifulsoup4 python3-mechanize python3-robotparser libusb-1.0-0 unrar curl libxml2 libxslt openvpn enigma2-plugin-systemplugins-serviceapp rtmpdump duktape astra-sm gstplayer gstreamer1.0-plugins-good gstreamer1.0-plugins-base gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly alsa-plugins alsa-utils"
PACKAGESPY2="p7zip wget python-imaging python-lxml python-requests python-pycrypto python-pyexecjs python-sqlite3 python-six python-codecs python-compression python-difflib python-xmlrpc python-html python-misc python-shell python-subprocess python-twisted-web python-unixadmin python-compression python-cryptography python-json python-netclient python-pyopenssl python-futures libusb-1.0-0 python-beautifulsoup4 python-mechanize python-robotparser unrar curl libxml2 libxslt openvpn kodi-addon-pvr-iptvsimple enigma2-plugin-systemplugins-serviceapp python-lzma rtmpdump hlsdl duktape f4mdump astra-sm gstplayer gstreamer1.0-plugins-good gstreamer1.0-plugins-base gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly alsa-plugins alsa-utils"
echo "Please Wait Until Opkg Update Finish ..."
WAIT_NET; opkg update >/dev/null 2>&1
if [ "$PYTHON" = "PY3" ]; then PKGS="$PACKAGESPY3"; else PKGS="$PACKAGESPY2"; fi
for PKG in $PKGS; do
  WAIT_NET
  if is_installed "$PKG"; then echo "Package '$PKG' is already installed, skipping..."; else echo "Installing package '$PKG'..."; timeout 60 opkg install "$PKG"; fi
done
sync
timeout 60 opkg install wget

# ============================================================
# دالة تثبيت البلجنات - سريعة - 5 محاولات - بعدها SKIP
# ============================================================
I() {
  NUM="$1"; NAME="$2"; URL="$3"
  T0=$(date +%s)
  if [ "$IS_NOT_NOVALER" = "1" ]; then
    case "$NAME" in
      novalerStore|novalerdownloader|ipaudiopro|ipaudioproplus|ipaudiopus|ipaudiopro-plus|RaedQuickSignal|readquicksignal|readQuickSignal)
        echo "== [$NUM] $NAME SKIPPED - Not Novaler Device =="; echo "$NUM" > "$P"; DONE=$NUM; return 0 ;;
    esac
  fi
  if [ "$NAME" = "aglare-pli" ] && { [ "$IS_ATV" = "1" ] || [ "$IS_EGAMI" = "1" ]; }; then
    echo "== [$NUM] aglare-pli SKIPPED - ATV/Egami - Will install aglareatv only - Prevent Bootloop =="; echo "$NUM" > "$P"; DONE=$NUM; return 0
  fi
  if [ "$NAME" = "aglare-fhd" ] && { [ "$IS_PLI" = "1" ] || [ "$IS_VIX" = "1" ] || [ "$IS_BH" = "1" ]; }; then
    echo "== [$NUM] aglare-fhd SKIPPED - PLi/ViX/BH - Will install aglarepli only =="; echo "$NUM" > "$P"; DONE=$NUM; return 0
  fi
  if [ "$NUM" -le "$DONE" ]; then return 0; fi
  echo "== [$NUM] $NAME =="
  WAIT_NET
  TRY=0; OK=0
  while [ "$TRY" -lt 5 ]; do
    TRY=$((TRY+1)); echo "   Try $TRY/5 - $NAME"
    rm -f /tmp/_i.sh; wget -q --no-check-certificate --tries=1 --timeout=15 "$URL" -O /tmp/_i.sh
    if [ -s /tmp/_i.sh ]; then OK=1; break; fi
    ALT_URL=$(echo "$URL" | sed -e 's|https://github.com/|https://raw.githubusercontent.com/|' -e 's|/raw/|/|')
    if [ "$ALT_URL" != "$URL" ]; then
      echo "   Primary failed (504?) - Trying Fallback"
      rm -f /tmp/_i.sh; wget -q --no-check-certificate --tries=1 --timeout=15 "$ALT_URL" -O /tmp/_i.sh
      if [ -s /tmp/_i.sh ]; then OK=1; break; fi
    fi
    echo "   Failed - Waiting 2 sec..."
    sleep 2
  done
  if [ "$OK" = "0" ]; then
    echo "== [$NUM] $NAME FAILED after 5 tries - SKIPPED - Going to next =="
    echo "$NUM" > "$P"; DONE=$NUM; return 0
  fi
  sed -i -e '/^[[:space:]]*reboot/d' -e '/reboot[[:space:]]*$/d' -e 's/;[[:space:]]*reboot/;/g' -e 's/&&[[:space:]]*reboot/&& echo [BLOCKED]/g' -e 's/shutdown.*/echo [BLOCKED]/g' -e '/systemctl.*reboot/d' -e '/systemctl.*poweroff/d' -e '/reboot -f/d' -e '/poweroff/d' -e '/halt/d' -e '/killall.*enigma2/d' -e '/killall[[:space:]]*-9[[:space:]]*enigma2/d' -e '/init 4/d' -e '/init 3/d' /tmp/_i.sh
  if [ "$NAME" = "FootOnsat" ] || [ "$NAME" = "FontOnsat" ]; then
    sed -i -e 's/^rand.*/choice=1; REPLY=1; install_method=1 # AUTO-FORCED-1/' -e 's/rand -.*/choice=1; REPLY=1; install_method=1/' -e 's/install_method=.*/install_method=1/' -e 's/choice=.*/choice=1/' -e 's/REPLY=.*/REPLY=1/' /tmp/_i.sh
    echo "   FootOnSat - Auto Choice = 1"
    ( for n in 1 2 3 4 5 6 7 8 9 10; do sleep 1; echo "1"; done ) | PATH="/tmp/noreboot:$PATH" /bin/sh /tmp/_i.sh
  else
    PATH="/tmp/noreboot:$PATH" /bin/sh /tmp/_i.sh
  fi
  T1=$(date +%s); echo "   [$NUM] $NAME Done in $((T1-T0)) sec - Total: $((T1-START_ALL)) sec"
  echo "$NUM" > "$P"; DONE=$NUM; rm -f /tmp/_i.sh; export PATH="/tmp/noreboot:$PATH"
}

# ============================================================
# SubExtractorLite - FIXED V21
# 6 URLs + Content Check + 600 sec + IPK Fallback + ZIP Fallback
# ============================================================
FIX_SUB() {
  if [ "35" -le "$DONE" ]; then return 0; fi
  echo "== [35] SubExtractorLite - Last Plugin - FIXED =="
  echo "   Log: /tmp/subextractor.log"
  : > /tmp/subextractor.log
  if [ "$PYTHON" = "PY2" ]; then echo "WARNING: SubExtractorLite Needs Python 3 - PY2 - Skipping" | tee -a /tmp/subextractor.log; echo "35" > "$P"; DONE=35; return 0; fi
  PYV=$(python3 --version 2>&1 | grep -o "3\.[0-9]*")
  echo "Python: $PYV" | tee -a /tmp/subextractor.log
  # لو متثبت اصلا - تخطي
  if ls /usr/lib/enigma2/python/Plugins/Extensions/SubExtractorLite* >/dev/null 2>&1 || opkg list-installed 2>/dev/null | grep -qi subextractor; then
    echo "SubExtractorLite Already Installed - Skipping" | tee -a /tmp/subextractor.log
    echo "35" > "$P"; DONE=35; return 0
  fi
  WAIT_NET; timeout 60 opkg install python3-pillow python3-requests python3-six python3-lxml 2>/dev/null | tee -a /tmp/subextractor.log
  # --- الطريقة 1: installer.sh من 6 لينكات ---
  SUB_URLS="https://raw.githubusercontent.com/Arian7s/SubExtractorLite/main/installer.sh https://raw.githubusercontent.com/Arian7s/subextractorlite/main/installer.sh https://raw.githubusercontent.com/Arian7s/SubExtractorLite/master/installer.sh https://raw.githubusercontent.com/Arian7s/subextractorlite/master/installer.sh"
  INSTALLED=0
  for U in $SUB_URLS; do
    echo "   Trying installer: $U" | tee -a /tmp/subextractor.log
    rm -f /tmp/sub.sh; WAIT_NET
    wget -q --no-check-certificate --tries=1 --timeout=20 "$U" -O /tmp/sub.sh
    # تحقق حقيقي: الملف موجود + حجمه > 500 + فيه كلمة subextractor + مش صفحة 404
    if [ -s /tmp/sub.sh ]; then
      SZ=$(wc -c < /tmp/sub.sh)
      if [ "$SZ" -gt 500 ] && grep -qi "subextractor" /tmp/sub.sh && ! grep -qi "404.*Not Found\|Not Found.*404" /tmp/sub.sh; then
        echo "   installer.sh OK - Size: $SZ - Running..." | tee -a /tmp/subextractor.log
        # شيل الريستارت بس - متشيلش باقي السكريبت
        sed -i -e '/restart_enigma2/d' -e '/^[[:space:]]*reboot/d' -e '/init 4/d' -e '/init 3/d' -e '/killall.*enigma2/d' /tmp/sub.sh
        PATH="/tmp/noreboot:$PATH" timeout 600 /bin/sh /tmp/sub.sh >> /tmp/subextractor.log 2>&1
        echo "   installer.sh Exit: $?" | tee -a /tmp/subextractor.log
        if ls /usr/lib/enigma2/python/Plugins/Extensions/SubExtractorLite* >/dev/null 2>&1 || opkg list-installed 2>/dev/null | grep -qi subextractor; then
          echo "SubExtractorLite Installed - OK - Via installer.sh" | tee -a /tmp/subextractor.log
          INSTALLED=1; break
        else
          echo "   installer.sh finished but plugin not found - Trying next method..." | tee -a /tmp/subextractor.log
        fi
      else
        echo "   Bad file - Size: $SZ - Probably 404 page - Skipping" | tee -a /tmp/subextractor.log
        head -c 300 /tmp/sub.sh >> /tmp/subextractor.log; echo "" >> /tmp/subextractor.log
      fi
    else
      echo "   Download failed - Empty" | tee -a /tmp/subextractor.log
    fi
    sleep 2
  done
  # --- الطريقة 2: IPK مباشر من Releases ---
  if [ "$INSTALLED" = "0" ]; then
    echo "   Trying Direct IPK From Releases..." | tee -a /tmp/subextractor.log
    ARCH=$(opkg print-architecture 2>/dev/null | grep -v "^all" | head -n 1 | awk '{print $2}')
    [ -z "$ARCH" ] && ARCH="cortexa15hf-neon-vfpv4"
    echo "   Arch: $ARCH - Python: $PYV" | tee -a /tmp/subextractor.log
    for REPO in "Arian7s/SubExtractorLite" "Arian7s/subextractorlite"; do
      WAIT_NET
      VER=$(wget -q --no-check-certificate -O - "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | grep -o '"tag_name": *"[^"]*"' | head -n 1 | cut -d'"' -f4 | tr -d 'vV')
      [ -z "$VER" ] && VER="1.0"
      echo "   Repo: $REPO - Version: $VER" | tee -a /tmp/subextractor.log
      for IPK_URL in "https://github.com/$REPO/releases/download/v${VER}/enigma2-plugin-extensions-subextractorlite_${VER}_${ARCH}_py${PYV}.ipk" "https://github.com/$REPO/releases/download/${VER}/enigma2-plugin-extensions-subextractorlite_${VER}_${ARCH}_py${PYV}.ipk" "https://raw.githubusercontent.com/$REPO/main/v${VER}/py${PYV}/${ARCH}/enigma2-plugin-extensions-subextractorlite_${VER}_${ARCH}_py${PYV}.ipk"; do
        echo "   Trying IPK: $IPK_URL" | tee -a /tmp/subextractor.log
        rm -f /tmp/sub.ipk; WAIT_NET
        wget -q --no-check-certificate --tries=1 --timeout=30 "$IPK_URL" -O /tmp/sub.ipk
        if [ -s /tmp/sub.ipk ]; then
          SZ=$(wc -c < /tmp/sub.ipk)
          # IPK لازم يبدأ بـ ar او debian-binary مش HTML
          if [ "$SZ" -gt 5000 ] && ! grep -qi "<html" /tmp/sub.ipk; then
            echo "   IPK OK - Size: $SZ - Installing..." | tee -a /tmp/subextractor.log
            timeout 120 opkg install --force-reinstall --force-overwrite --force-downgrade /tmp/sub.ipk >> /tmp/subextractor.log 2>&1
            if ls /usr/lib/enigma2/python/Plugins/Extensions/SubExtractorLite* >/dev/null 2>&1 || opkg list-installed 2>/dev/null | grep -qi subextractor; then
              echo "SubExtractorLite Installed - OK - Via Direct IPK" | tee -a /tmp/subextractor.log
              INSTALLED=1; break
            fi
          else
            echo "   Bad IPK - Size: $SZ - HTML page" | tee -a /tmp/subextractor.log
          fi
        fi
      done
      [ "$INSTALLED" = "1" ] && break
    done
  fi
  # --- الطريقة 3: ZIP من github ---
  if [ "$INSTALLED" = "0" ]; then
    echo "   Trying ZIP Fallback..." | tee -a /tmp/subextractor.log
    for Z in "https://github.com/Arian7s/SubExtractorLite/archive/refs/heads/main.zip" "https://github.com/Arian7s/subextractorlite/archive/refs/heads/main.zip"; do
      rm -f /tmp/sub.zip; WAIT_NET
      wget -q --no-check-certificate --tries=1 --timeout=30 "$Z" -O /tmp/sub.zip
      if [ -s /tmp/sub.zip ]; then
        SZ=$(wc -c < /tmp/sub.zip)
        if [ "$SZ" -gt 5000 ] && ! grep -qi "<html" /tmp/sub.zip; then
          echo "   ZIP OK - Size: $SZ - Extracting..." | tee -a /tmp/subextractor.log
          cd /tmp && unzip -o /tmp/sub.zip >> /tmp/subextractor.log 2>&1
          FOLDER=$(ls -d /tmp/SubExtractorLite* /tmp/subextractorlite* 2>/dev/null | head -n 1)
          echo "   Folder: $FOLDER" | tee -a /tmp/subextractor.log
          if [ -n "$FOLDER" ]; then
            mkdir -p /usr/lib/enigma2/python/Plugins/Extensions/SubExtractorLite
            cp -a "$FOLDER"/SubExtractorLite/* /usr/lib/enigma2/python/Plugins/Extensions/SubExtractorLite/ 2>/dev/null
            cp -a "$FOLDER"/* /usr/lib/enigma2/python/Plugins/Extensions/SubExtractorLite/ 2>/dev/null
            rm -rf /tmp/SubExtractorLite* /tmp/subextractorlite* /tmp/sub.zip
            if ls /usr/lib/enigma2/python/Plugins/Extensions/SubExtractorLite* >/dev/null 2>&1; then
              echo "SubExtractorLite Installed - OK - Via ZIP" | tee -a /tmp/subextractor.log
              INSTALLED=1; break
            fi
          fi
        fi
      fi
    done
  fi
  if [ "$INSTALLED" = "0" ]; then
    echo "== [35] SubExtractorLite FAILED - All 3 methods failed - Check /tmp/subextractor.log ==" | tee -a /tmp/subextractor.log
  fi
  echo "35" > "$P"; DONE=35; rm -f /tmp/sub.sh /tmp/sub.ipk /tmp/sub.zip
}

# ============================================================
# اوامر البلوجنات المتصلحة - بعد اوامر الباكدجات - 35 بلجن
# ============================================================
I "1" "MyStreamer" "https://raw.githubusercontent.com/popking159/MyStreamer/refs/heads/main/myinstaller.sh"
I "2" "novalerdownloader" "https://raw.githubusercontent.com/popking159/novalerdownloader/refs/heads/main/myinstaller.sh"
I "3" "AJPanel" "https://raw.githubusercontent.com/AMAJamry/AJPanel/main/installer.sh"
I "4" "SubsSupportPro" "https://raw.githubusercontent.com/popking159/SubsSupportPro/refs/heads/main/myinstaller.sh"
I "5" "internet-speedtest" "https://raw.githubusercontent.com/emilnabil/download-plugins/refs/heads/main/internet-speedtest.sh"
I "6" "EmuInstaller" "https://raw.githubusercontent.com/popking159/EmuInstaller/refs/heads/main/myinstaller.sh"
I "7" "IPAudioPro" "https://raw.githubusercontent.com/zKhadiri/IPAudioPro-Releases-/main/installer.sh"
I "8" "Epg-Grabber" "https://dreambox4u.com/emilnabil237/plugins/Epg-Grabber/installer.sh"
I "9" "EmilRemovePackage" "https://raw.githubusercontent.com/emilnabil/download-plugins/refs/heads/main/EmilRemovePackage/EmilRemovePackage.sh"
I "10" "customchannelselection" "https://raw.githubusercontent.com/popking159/customchannelselection/refs/heads/main/myinstaller.sh"
I "11" "crashlogviewer" "https://dreambox4u.com/emilnabil237/plugins/crashlogviewer/crashlogviewer_1.9.sh"
I "12" "cacheflush" "https://raw.githubusercontent.com/popking159/cacheflush/refs/heads/main/myinstaller.sh"
I "13" "bitrate" "https://raw.githubusercontent.com/emilnabil/download-plugins/refs/heads/main/bitrate/bitrate.sh"
I "14" "AutoZap-Recovery" "https://raw.githubusercontent.com/HBK2010/-AutoZap-Recovery-by-Ahmad-Alamri/main/installer.sh"
I "15" "ArabicSavior" "https://raw.githubusercontent.com/popking159/ArabicSavior/refs/heads/main/myinstaller.sh"
if [ "16" -le "$DONE" ]; then :; else WAIT_NET; cd /usr/lib/enigma2/python/Plugins/Extensions || true; rm -rf SimplySports; TRY=0; OK=0; while [ "$TRY" -lt 5 ]; do TRY=$((TRY+1)); echo "   Try $TRY/5 - SimplySports"; rm -f SimplySports.zip; wget -q --no-check-certificate --tries=1 --timeout=15 https://github.com/Ahmed-Mohammed-Abbas/SimplySports/archive/refs/heads/main.zip -O SimplySports.zip; if [ -s SimplySports.zip ]; then OK=1; break; fi; echo "   Failed - Waiting 2 sec..."; sleep 2; done; if [ "$OK" = "0" ]; then echo "== [16] SimplySports FAILED after 5 tries - SKIPPED =="; else unzip -o SimplySports.zip; mv SimplySports-main SimplySports; rm -f SimplySports.zip; echo "== [16] SimplySports Done =="; fi; echo "16" > "$P"; DONE=16; fi
I "17" "buttonpatcher" "https://raw.githubusercontent.com/popking159/buttonpatcher/refs/heads/main/myinstaller.sh"
I "18" "FootOnsat" "https://dreambox4u.com/emilnabil237/plugins/FootOnsat/installer.sh"
I "19" "LunaTV" "https://raw.githubusercontent.com/popking159/LukaTV/refs/heads/main/myinstaller.sh"
I "20" "novalerStore" "https://raw.githubusercontent.com/emilnabil/download-plugins/refs/heads/main/novaler/novalerStore.sh"
I "21" "ipaudioproplus" "https://raw.githubusercontent.com/emilnabil/download-plugins/refs/heads/main/novaler/ipaudioplus.sh"
I "22" "aglare-pli" "https://raw.githubusercontent.com/popking159/skins/refs/heads/main/aglarepli/installer.sh"
I "23" "aglare-fhd" "https://raw.githubusercontent.com/popking159/skins/refs/heads/main/aglareatv/installer.sh"
I "24" "RaedQuickSignal" "https://raw.githubusercontent.com/fairbird/RaedQuickSignal/main/installer.sh"
I "25" "NewVirtualKeyBoard" "https://raw.githubusercontent.com/fairbird/NewVirtualKeyBoard/main/installer.sh"
I "26" "AutoBiss" "https://raw.githubusercontent.com/emilnabil/download-plugins/refs/heads/main/AutoBiss/AutoBiss.sh"
I "27" "auto-dcw-key-add" "https://raw.githubusercontent.com/emilnabil/download-plugins/refs/heads/main/auto-dcw-key-add/auto-dcw-key-add.sh"
I "28" "FuryBiss" "https://raw.githubusercontent.com/islam-2412/FuryBiss/refs/heads/main/fury/installer.sh"
I "29" "hisnmuslim" "https://raw.githubusercontent.com/emilnabil/download-plugins/refs/heads/main/hisnmuslim/hisnmuslim.sh"
I "30" "netusagepro" "https://raw.githubusercontent.com/emilnabil/download-plugins/refs/heads/main/netusagepro/netusagepro.sh"
I "31" "quran" "https://raw.githubusercontent.com/emil237/quran/main/installer.sh"
I "32" "myhits" "https://raw.githubusercontent.com/popking159/myhits/refs/heads/main/myinstaller.sh"
I "33" "oscam-by-lenuxsat" "https://dreambox4u.com/emilnabil237/emu/oscam-by-lenuxsat/installer.sh"
if [ "34" -le "$DONE" ]; then :; else WAIT_NET; TRY=0; OK=0; while [ "$TRY" -lt 5 ]; do TRY=$((TRY+1)); echo "   Try $TRY/5 - AutoSub"; rm -f /tmp/AutoSub.tar.gz; wget -q --no-check-certificate --tries=1 --timeout=15 -O /tmp/AutoSub.tar.gz https://raw.githubusercontent.com/HBK2010/AutoSub/main/AutoSub.tar.gz; if [ -s /tmp/AutoSub.tar.gz ]; then OK=1; break; fi; echo "   Failed - Waiting 2 sec..."; sleep 2; done; if [ "$OK" = "0" ]; then echo "== [34] AutoSub FAILED after 5 tries - SKIPPED =="; else tar xzf /tmp/AutoSub.tar.gz -C /usr/lib/enigma2/python/Plugins/Extensions; rm -f /tmp/AutoSub.tar.gz; echo "== [34] AutoSub Done =="; fi; echo "34" > "$P"; DONE=34; fi
FIX_SUB

# ============================================================
# ثالثا - قايمة اختيار ملف القنوات - English Only
# ============================================================
clear
echo "========================================"
echo "   All-Script By Eng Ahmed Abdel-Moati"
echo "   Copyright (c) 2026 Eng / Ahmed Abdel-Moati"
echo "========================================"
echo ""
echo "   Select Channel List to Install:"
echo ""
echo "----------------------------------------"
echo "   [ 1 ]   Emil Nabil"
echo "         Full List - Main List"
echo ""
echo "   [ 2 ]   Hazem Wahba"
echo "         Full List"
echo ""
echo "   [ 3 ]   Khaled"
echo "         Full List"
echo ""
echo "   [ 4 ]   Mnasr"
echo "         Full List"
echo "----------------------------------------"
echo "   [ 0 ]   Skip"
echo "         Continue Without Channel List"
echo "----------------------------------------"
echo ""
echo "   Note: Choose one number only from 0 to 4"
while true; do
  printf "   Enter Number Here and Press Enter [ 0-4 ] : "; read CH
  case "$CH" in
    1) CH_NAME="Emil Nabil"; CH_URL="https://raw.githubusercontent.com/emin237/channel-emil-nabil/main/installer.sh"; break ;;
    2) CH_NAME="Hazem Wahba"; CH_URL="https://raw.githubusercontent.com/emin237/channel-hazem-wahba/main/installer.sh"; break ;;
    3) CH_NAME="Khaled"; CH_URL="https://raw.githubusercontent.com/emin237/channel-khaled/main/installer.sh"; break ;;
    4) CH_NAME="Mnasr"; CH_URL="https://raw.githubusercontent.com/emin237/channel-mnasr/main/installer.sh"; break ;;
    0) CH_NAME="Skip"; break ;;
    *) echo ""; echo "   !!! Wrong Number - Enter Number From 0 to 4 Only !!!"; echo "";;
  esac
done
if [ "$CH" = "0" ]; then echo ""; echo "   Skipped - Continue Without Channel List";
else
  echo ""; echo "   You Selected : $CH_NAME"
  printf "   Are You Sure ? Type y to Confirm or n to Cancel [ y/n ] : "; read CONFIRM
  if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ] || [ "$CONFIRM" = "1" ]; then
    echo ""; echo "   Downloading Channel List ... Please Wait ..."
    WAIT_NET
    wget -q --no-check-certificate "$CH_URL" -O - | PATH="/tmp/noreboot:$PATH" /bin/sh
    echo ""; echo "   Done - Channel List Installed Successfully"
  else echo ""; echo "   Cancelled - Continue Without Channel List"; fi
fi

# ============================================================
# خامسا - Restore حسب الصورة
# ============================================================
echo ""; echo "   Restore Private Backup ?"
echo "   [ 1 ] Yes - Restore Settings + Private Channels + OSCam"
echo "   [ 0 ] No - Skip Restore"
printf "   Enter [ 0-1 ] : "; read RB
if [ "$RB" = "1" ]; then
  if [ "$IS_PLI" = "1" ] || [ "$IS_VIX" = "1" ] || [ "$IS_BH" = "1" ]; then BK="/media/hdd/backup/pli_bh_vix /media/usb/backup/pli_bh_vix"; IMG_N="PLi_ViX_BH"; fi
  if [ "$IS_ATV" = "1" ] || [ "$IS_EGAMI" = "1" ]; then BK="/media/hdd/backup/atv_egami /media/usb/backup/atv_egami"; IMG_N="ATV_Egami"; fi
  BKP=""; for d in $BK; do if [ -d "$d" ]; then BKP="$d"; break; fi; done
  if [ -z "$BKP" ]; then echo "   No Backup Found for $IMG_N in $BK";
  else
    echo "   Found Backup : $BKP - Restoring $IMG_N"
    if [ "$IS_ATV" = "1" ] || [ "$IS_EGAMI" = "1" ]; then
      cp -a "$BKP"/timers.xml "$BKP"/autotimer.xml "$BKP"/epg.dat /etc/enigma2/ 2>/dev/null
      cp -a "$BKP"/userbouquet.* "$BKP"/bouquets.* "$BKP"/lamedb "$BKP"/blacklist /etc/enigma2/ 2>/dev/null
      cp -a "$BKP"/oscam.* /etc/tuxbox/config/ 2>/dev/null
      cp -a "$BKP"/SoftCam.Key /usr/keys/ 2>/dev/null
      grep -v "config.skin.primary_skin\|config.skin.display_skin" "$BKP"/settings > /etc/enigma2/settings 2>/dev/null
      echo "   ATV/Egami Restore Done - From atv_egami folder - Skin line removed to prevent Bootloop"
    fi
    if [ "$IS_PLI" = "1" ] || [ "$IS_VIX" = "1" ] || [ "$IS_BH" = "1" ]; then
      cp -a "$BKP"/settings "$BKP"/timers.xml /etc/enigma2/ 2>/dev/null
      cp -a "$BKP"/userbouquet.* "$BKP"/bouquets.* "$BKP"/lamedb /etc/enigma2/ 2>/dev/null
      cp -a "$BKP"/oscam.* /etc/tuxbox/config/ 2>/dev/null
      cp -a "$BKP"/SoftCam.Key /usr/keys/ 2>/dev/null
      echo "   PLi/ViX/BH Restore Done - From pli_bh_vix folder"
    fi
    chmod 755 /etc/tuxbox/config/oscam.* 2>/dev/null
  fi
fi

# ============================================================
# سادسا - Backup FULL IMAGE
# ============================================================
echo ""; echo "   Do you want to make FULL IMAGE Backup now ?"
echo "   [ 1 ] Yes - FULL IMAGE Backup - Can Flash Again"
echo "   [ 0 ] No - Skip Backup"
printf "   Enter [ 0-1 ] : "; read DO_BK
if [ "$DO_BK" = "1" ]; then
  if [ "$IS_ATV" = "1" ]; then IMG="atv"; elif [ "$IS_EGAMI" = "1" ]; then IMG="egami"; elif [ "$IS_PLI" = "1" ]; then IMG="pli"; elif [ "$IS_BH" = "1" ]; then IMG="bh"; elif [ "$IS_VIX" = "1" ]; then IMG="vix"; else IMG="unknown"; fi
  DATE_NOW=$(date +%Y-%m-%d_%H-%M)
  FULL_DIR="/media/hdd/backup/fullimage_${IMG}_${DATE_NOW}"
  mkdir -p "$FULL_DIR"; echo "   FULL Backup to : $FULL_DIR"
  echo "   This may take 5-15 minutes - Do NOT turn off device..."
  WAIT_NET
  if [ -f /usr/lib/enigma2/python/Plugins/SystemPlugins/BackupSuite/backup.sh ]; then
    echo "   Using BackupSuite - Full Image..."
    mkdir -p /media/hdd/backupsuite
    PATH="/tmp/noreboot:$PATH" /bin/sh /usr/lib/enigma2/python/Plugins/SystemPlugins/BackupSuite/backup.sh /media/hdd/backupsuite
    cp -a /media/hdd/backupsuite/* "$FULL_DIR/" 2>/dev/null; ls -lh "$FULL_DIR"
  elif [ -f /usr/lib/enigma2/python/Plugins/Extensions/dBackup/plugin.py ]; then
    echo "   Using dBackup - Full Image..."
    echo "   Please run dBackup from Menu > Plugins > dBackup"
  elif [ -f /usr/lib/enigma2/python/Plugins/SystemPlugins/SoftwareManager/ImageBackup.py ]; then
    echo "   Using Built-in ImageBackup..."
    python3 -c "from Plugins.SystemPlugins.SoftwareManager.ImageBackup import ImageBackup; ImageBackup()" 2>/dev/null
    cp -a /media/hdd/imagebackup/* "$FULL_DIR/" 2>/dev/null; ls -lh "$FULL_DIR"
  else
    echo "   BackupSuite not found - Installing it..."
    WAIT_NET; opkg update; opkg install enigma2-plugin-systemplugins-backupsuite
    if [ -f /usr/lib/enigma2/python/Plugins/SystemPlugins/BackupSuite/backup.sh ]; then
      echo "   BackupSuite Installed - Running Full Backup..."
      mkdir -p /media/hdd/backupsuite
      PATH="/tmp/noreboot:$PATH" /bin/sh /usr/lib/enigma2/python/Plugins/SystemPlugins/BackupSuite/backup.sh /media/hdd/backupsuite
      cp -a /media/hdd/backupsuite/* "$FULL_DIR/" 2>/dev/null; ls -lh "$FULL_DIR"
    else
      echo "   Fallback - Full System TAR Backup..."
      tar czf "$FULL_DIR/full_system_backup.tar.gz" --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/tmp --exclude=/media/hdd --exclude=/media/usb --exclude=/mnt / 2>/dev/null
      ls -lh "$FULL_DIR/full_system_backup.tar.gz"
    fi
  fi
  echo "   FULL IMAGE Backup Done - $FULL_DIR"; ls -lh "$FULL_DIR"
  echo "   Copy this folder to PC - You can flash it again anytime"
fi

# ============================================================
# حل مشكلة Bootloop في OpenATV - قبل الريستارت الاخير
# ============================================================
FIX_BOOTLOOP_ATV() {
  echo ""; echo "== Checking For Bootloop Risk - Before Final Reboot =="
  rm -f /media/hdd/enigma2_crash*.log /home/root/logs/enigma2_crash*.log /tmp/enigma2_crash*.log 2>/dev/null
  if [ "$IS_ATV" = "1" ] || [ "$IS_EGAMI" = "1" ]; then
    SKIN_NOW=$(grep "config.skin.primary_skin" /etc/enigma2/settings 2>/dev/null | cut -d'=' -f2)
    echo "   Current Skin: $SKIN_NOW"
    if echo "$SKIN_NOW" | grep -qi "aglare.*pli\|pli.*aglare"; then
      echo "   WARNING: Found aglare-pli skin on ATV - This causes Bootloop - Removing it..."
      sed -i '/config.skin.primary_skin/d' /etc/enigma2/settings
      echo "   Skin reset to Default - Bootloop Fixed"
    fi
    if echo "$SKIN_NOW" | grep -qi "aglare"; then
      if [ ! -d "/usr/share/enigma2/Aglare-FHD" ] && [ ! -d "/usr/share/enigma2/aglare" ]; then
        echo "   WARNING: Aglare skin in settings but not installed - Resetting to Default..."
        sed -i '/config.skin.primary_skin/d' /etc/enigma2/settings
      fi
    fi
    if [ ! -s /etc/enigma2/settings ]; then
      echo "   WARNING: settings file empty/corrupted - Restoring backup..."
      cp -a /media/hdd/backup/before_allscript/settings.bak /etc/enigma2/settings 2>/dev/null
    fi
    echo "   ATV Bootloop Check Done - Safe To Reboot"
  fi
  export PATH="$O"
  timeout 60 opkg configure -a 2>/dev/null
  sync; sleep 2
  echo "   All Packages Configured - Ready For Reboot"
}
FIX_BOOTLOOP_ATV

END_ALL=$(date +%s)
echo ""; echo "Total Time: $((END_ALL-START_ALL)) sec - Copyright (c) 2026 Eng / Ahmed Abdel-Moati - ALL DONE - REAL restart now"
export PATH="$O"; rm -rf /tmp/noreboot /tmp/_i.sh; sleep 2; reboot; exit 0