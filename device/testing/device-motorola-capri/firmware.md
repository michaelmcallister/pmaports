# Moto G10 firmware

`firmware-motorola-capri` installs firmware path aliases and depends on the
standard firmware packages and `msm-firmware-loader`. Proprietary binaries and
per-device calibration are read from the handset's preserved Android partitions
at boot. No manual copy into the root filesystem is required.

Keep firmware and calibration from the same handset and panel variant. Retain
backups before replacing Android; another phone's calibration is not a substitute.

## Firmware sources

| Component | Source |
| --- | --- |
| GPU command processor | `firmware-qcom-adreno-a630-sqe` |
| Bluetooth | `linux-firmware-qca` |
| Wi-Fi capability descriptor | `linux-firmware-ath10k`, WCN3990/qcm2290 variant |
| Modem, ADSP, GPU authentication and WLAN firmware | Active-slot `modem` and `dsp` partitions |
| Touchscreen and speaker amplifier firmware | Active-slot `vendor` partition inside `super` |
| Sensor configuration | Active-slot `vendor/etc/sensors/sns_reg_config` |
| Sensor calibration | `persist/sensors/registry/registry` |
| Modem EFS | This handset's `modemst1`, `modemst2` and `fsc` partitions |

`msm-firmware-loader` selects the active Android slot, maps dynamic partitions,
and mounts firmware filesystems read-only with journal replay disabled. Its
runtime firmware tree is under `/run/msm-firmware-loader/target`. The sensor
registry is copied into that temporary tree with permissions suitable for the
unprivileged FastRPC service; the original calibration is unchanged.

RMTFS reads the preserved EFS partitions with `-r -P`. Firmware writes remain in
memory and do not modify those partitions. The touchscreen driver loads after
firmware provisioning during userspace startup.

Preserve `super`, `modem`, `dsp`, `bluetooth`, `persist`, the EFS partitions, and
the original `vendor_boot` and DTBO partitions. Flash only `userdata` and `boot`
as described in [the installation instructions](README.md). The Git repositories
contain source and packaging, without private firmware or calibration backups.

## RTC offset

The PMIC RTC is a running counter that Linux cannot set. `swclock-offset` saves
the difference between system time and this counter at shutdown and restores
it at boot. Synchronize the system clock over the network before the first
shutdown, and preserve `/var/cache/swclock-offset/offset-storage` in backups.
