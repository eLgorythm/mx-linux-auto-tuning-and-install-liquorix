#!/bin/bash
# MX Linux Zen Kernel + Optimasi Desktop + Auto Clear Cache + Reset Opsi
# Tested on MX Linux 23 (Debian 12 base)

if [[ $EUID -ne 0 ]]; then
    echo "Harus dijalankan sebagai root!"
    exit 1
fi

echo "======================================="
echo " MX Linux Zen Kernel Optimizer"
echo "======================================="
echo "1) Install & Optimasi Zen Kernel (Liquorix)"
echo "2) Reset ke Kernel Default & Hapus Tweak"
echo "======================================="
read -p "Pilih opsi (1/2): " pilihan

if [[ "$pilihan" == "1" ]]; then
    echo "[1/5] Menambahkan repo Liquorix..."
    echo 'deb http://liquorix.net/debian bookworm main' | tee /etc/apt/sources.list.d/liquorix.list
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 9AE4078033C2352D

    echo "[2/5] Update repo & install Zen kernel..."
    apt update
    apt install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64

    echo "[3/5] Mengatur scheduler I/O dan CPU governor..."
    for disk in /sys/block/*; do
        if [[ -f "$disk/queue/scheduler" ]]; then
            echo 'mq-deadline' > "$disk/queue/scheduler"
        fi
    done
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo 'schedutil' > "$cpu"
    done
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
    cat > /usr/local/bin/clear_cache.sh <<'EOF'
#!/bin/bash
sync; echo 3 > /proc/sys/vm/drop_caches
EOF
    chmod +x /usr/local/bin/clear_cache.sh
    (crontab -l 2>/dev/null; echo "*/30 * * * * /usr/local/bin/clear_cache.sh") | crontab -

    echo "✅ Instalasi & optimasi selesai! Silakan reboot."

elif [[ "$pilihan" == "2" ]]; then
    echo "[1/5] Menghapus Zen kernel (Liquorix)..."
    apt remove --purge -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64
    apt autoremove -y

    echo "[2/5] Menghapus repo Liquorix..."
    rm -f /etc/apt/sources.list.d/liquorix.list
    apt-key del 9AE4078033C2352D 2>/dev/null || true
    apt update

    echo "[3/5] Menghapus tweak scheduler & CPU governor..."
    rm -f /etc/udev/rules.d/60-scheduler.rules
    rm -f /etc/udev/rules.d/70-cpu-governor.rules

    echo "[4/5] Menghapus optimasi swappiness & cache pressure..."
    sed -i '/vm.swappiness=10/d' /etc/sysctl.conf
    sed -i '/vm.vfs_cache_pressure=50/d' /etc/sysctl.conf
    sysctl -p

    echo "[5/5] Menghapus auto-clear cache..."
    rm -f /usr/local/bin/clear_cache.sh
    crontab -l | grep -v "/usr/local/bin/clear_cache.sh" | crontab -

    echo "✅ Reset selesai! Silakan reboot untuk kembali ke kernel default."

else
    echo "❌ Pilihan tidak valid."
fi
