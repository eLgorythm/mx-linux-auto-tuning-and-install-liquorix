#!/bin/bash
# MX Linux Zen Kernel + Optimasi Desktop
# Tested on MX Linux 23 (Debian 12 base)

# Pastikan dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
    echo "Harus dijalankan sebagai root!"
    exit 1
fi

echo "[1/4] Menambahkan repo Liquorix..."
echo 'deb http://liquorix.net/debian bookworm main' | tee /etc/apt/sources.list.d/liquorix.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9AE4078033C2352D

echo "[2/4] Update repo & install Zen kernel..."
apt update
apt install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64

echo "[3/4] Mengatur scheduler I/O dan CPU governor..."
# Set default I/O scheduler
echo 'mq-deadline' > /sys/block/sda/queue/scheduler 2>/dev/null
echo 'mq-deadline' > /sys/block/nvme0n1/queue/scheduler 2>/dev/null

# Set default CPU governor
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo 'schedutil' > "$cpu"
done

# Agar persistent setelah reboot
cat > /etc/udev/rules.d/60-scheduler.rules <<EOF
ACTION=="add|change", KERNEL=="sda", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="nvme0n1", ATTR{queue/scheduler}="mq-deadline"
EOF

cat > /etc/udev/rules.d/70-cpu-governor.rules <<EOF
SUBSYSTEM=="cpu", KERNEL=="cpu[0-9]*", ATTR{cpufreq/scaling_governor}="schedutil"
EOF

echo "[4/4] Optimasi swappiness & cache pressure..."
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
sysctl -p

echo "✅ Selesai! Silakan reboot untuk mulai menggunakan Zen kernel."
