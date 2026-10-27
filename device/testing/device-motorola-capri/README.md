# Motorola Moto G10

Device support for the Motorola Moto G10 (`motorola-capri`, Snapdragon 460).
The tested variant is an XT2127-2 with the DJN NT36525B display panel. Other
panel variants have not been tested.

The kernel and device tree are maintained in
[linux-motorola-capri](https://github.com/michaelmcallister/linux-motorola-capri).
The kernel package builds a pinned source archive with LLVM; a separate kernel
checkout is not required.

## Hardware support

Display, touchscreen, accelerated graphics, Wi-Fi, speaker output, USB host,
USB audio and accelerometer-based rotation work with the required firmware.
Battery reporting uses an approximate voltage/current-based estimate. USB
charging is enabled with temperature monitoring; full-cycle accuracy and
charging behaviour across all temperatures have not been validated.

RTC and power-button wake have been tested with systemd, including touchscreen
input, sensor recovery and brightness restoration after resume. Phosh suspends
after 15 minutes idle on battery and stays awake while plugged in. Display
geometry and wakeup-key definitions are provided by gmobile.

Bluetooth initialization and discovery work; pairing and sustained profiles
remain untested. Cellular service has not been validated with a SIM. Camera
support is not included in this branch. Rotation can briefly blank the display
while the shell redraws.

Phosh is the tested graphical interface. The device package provides its display
scaling and rotation defaults; applications are selected separately. Clean
installations with both OpenRC and systemd have been tested.

## Building

This branch requires the `bootimg_preserve_vendor_boot` support in pmbootstrap,
boot-deploy and postmarketos-mkinitfs. The latter two are packaged here. Until the
pmbootstrap change is merged, use the `capri-preserve-vendor` branch of
[the pmbootstrap fork](https://github.com/michaelmcallister/pmbootstrap).

From this pmaports checkout:

```sh
pmbootstrap -p "$PWD" init
```

Select **edge**, **motorola / capri**, your service manager and preferred UI.
Use **systemd** and **Phosh** for the configuration tested for suspend and wake.
Build the shared packages first, since their patched versions are not available
from the distribution repositories:

```sh
pmbootstrap -p "$PWD" build boot-deploy postmarketos-mkinitfs \
    make-dynpart-mappings msm-firmware-loader swclock-offset \
    libssc iio-sensor-proxy alsa-ucm-conf gmobile postmarketos-ui-phosh
```

For systemd installations, also build its base package:

```sh
pmbootstrap -p "$PWD" build postmarketos-base-systemd
```

Then build the device packages and image:

```sh
pmbootstrap -p "$PWD" build linux-motorola-capri device-motorola-capri
pmbootstrap -p "$PWD" install --single-partition --filesystem ext4
pmbootstrap -p "$PWD" export
```

The root filesystem occupies `userdata` as a single ext4 filesystem, without a
partition table. Firmware is loaded automatically from standard firmware packages
and the preserved Android partitions; see [firmware.md](firmware.md).

## Installation

The bootloader must be unlocked. Flashing `userdata` erases the existing Android
or Linux installation and application data. Back up the phone before proceeding.
Retain the original `vendor_boot`, DTBO, firmware and calibration partitions.

From fastboot, using the files in the pmbootstrap export directory:

```sh
fastboot flash userdata motorola-capri.img
fastboot boot boot.img
```

After checking the temporary boot, install the boot image permanently:

```sh
fastboot flash boot boot.img
```

The patched pmbootstrap also supports `flasher flash_rootfs`, `flasher boot` and
`flasher flash_kernel`. Kernel and initramfs updates regenerate `boot.img` and
update the boot partition through boot-deploy, preserving stock `vendor_boot`.

## Boot and hardware integration

The Motorola bootloader requires an alignment wrapper around the kernel. The
kernel embeds its device tree and retains selected information from the firmware
tree. These compatibility helpers live in the kernel source and are called by
its APKBUILD.

The initramfs and kernel command line belong in the header-v3 `boot.img`, while
stock `vendor_boot` is retained. The shared boot tools implement this layout and
handle the stock vendor ramdisk's real `/lib` directory. Kernel parameters use
the normal `kernel-cmdline.d` configuration; regenerate the initramfs after
changing them. The null-console driver is built in because the bootloader
selects `console=null`.

Board services start the modem before ADSP, allowing stock firmware to hand the
speaker pins to LPASS, and restore the bootloader-provided Bluetooth address.
The standard `rmtfs`, `tqftpserv` and `hexagonrpcd` packages serve remote firmware
requests. Sensor discovery uses libssc and iio-sensor-proxy. The kernel provides
Qualcomm protection-domain mapping.

`swclock-offset` handles the read-only RTC, and `qbootctl` marks the current
Android A/B slot successful. The watchdog is serviced by OpenRC's watchdog
service or systemd's runtime watchdog support.
