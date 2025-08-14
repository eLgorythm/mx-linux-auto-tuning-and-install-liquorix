#!/bin/bash
# MX Linux Zen Kernel + Optimasi Desktop + Auto Clear Cache
# Tested on MX Linux 23 (Debian 12 base)

if [[ $EUID -ne 0 ]]; then
    echo "Harus dijalankan sebagai root!"
    exit 1
fi

echo "[1/5] Menambahkan repo Liquorix..."
echo 'deb http://liquorix.net/debian bookworm main' | tee /etc/apt/sources.list.d/liquorix.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9AE4078033C2352D

echo "[2/5] Update repo & install Zen kernel..."
apt update
apt install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64

echo "[3/5] Mengatur scheduler I/O dan CPU governor..."
# Set scheduler sekarang
for disk in /sys/block/*; do
    if [[ -f "$disk/queue/scheduler" ]]; then
        echo 'mq-deadline' > "$disk/queue/scheduler"
    fi
done

# Set CPU governor sekarang
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo 'schedutil' > "$cpu"
done

# Bikin aturan agar persistent setelah reboot
cat > /etc/udev/rules.d/60-scheduler.rules <<EOF
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="mq-deadline"
EOF

cat > /etc/udev/rules.d/70-cpu-governor.rules <<EOF
SUBSYSTEM=="cpu", KERNEL=="cpu[0-9]*", ATTR{cpufreq/scaling_governor}="schedutil"
EOF

echo "[4/5] Optimasi swappiness & cache pressure..."
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
sysctl -p

echo "[5/5] Membuat auto-clear cache tiap 30 menit..."
# Script clear cache
cat > /usr/local/bin/clear_cache.sh <<'EOF'
#!/bin/bash
sync; echo 3 > /proc/sys/vm/drop_caches
EOF
chmod +x /usr/local/bin/clear_cache.sh

# Tambahkan ke cron
(crontab -l 2>/dev/null; echo "*/30 * * * * /usr/local/bin/clear_cache.sh") | crontab -

echo "✅ Selesai! Reboot untuk mulai menggunakan Zen kernel dengan optimasi."
echo "ℹ️ Cache akan otomatis dibersihkan setiap 30 menit."
