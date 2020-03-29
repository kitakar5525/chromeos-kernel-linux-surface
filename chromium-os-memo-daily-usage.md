## memo for using Chromium OS

### Some HID devices stop working after suspend (s2idle) by default

You may see some logs after s2idle in `dmesg` like this:
```
i2c_hid i2c-MSHW0030:00: failed to retrieve report from device.
```

Then, build `HID` as module (`I2C_HID`=m is not sufficient (?) in my case)
and reload the module `sudo modprobe -r i2c_hid && sudo modprobe i2c_hid`

### Tap to click not working by default

Edit `/etc/gesture/40-touchpad-cmt.conf`
```diff
Section "InputClass"
    Identifier      "touchpad"
[...]
+    # for Surface series touchpad tap to click
+    Option          "libinput Tapping Enabled" "1"
+    Option          "Tap Minimum Pressure" "0.1"
EndSection
```

then `sudo restart ui`

References:
- [Problem With alps touchpad ? Issue #128 ? arnoldthebat/chromiumos](https://github.com/arnoldthebat/chromiumos/issues/128)

### ~~FIXME: Sound not working on Surface 3~~ Managed to work: Sound not working on Surface 3 by default
`dmesg` says:
```
Audio Port: ASoC: no backend DAIs enabled for Audio Port
```

HDMI or USB audio is working.

---

I managed to make the sound working on Surface 3, not ideal result yet.
- Obtain UCM files for chtrt5645 from [UCM/chtrt5645 at master · plbossart/UCM](https://github.com/plbossart/UCM/tree/master/chtrt5645)
- Place these 2 .conf files into a directory named `chtrt5645`
- Copy the directory into `/usr/share/alsa/ucm/`

Then, reboot.

If it is still not working, you may manually switch Speaker or Headphones:
- `alsaucm -c chtrt5645 set _verb HiFi set _enadev Speaker`
- `alsaucm -c chtrt5645 set _verb HiFi set _enadev Headphones`

References:
[ALSA (chtrt5645/HdmiLpeAudio) no audio / Newbie Corner / Arch Linux Forums](https://bbs.archlinux.org/viewtopic.php?id=239674)

### Sound on Surface Book 1 may not working by default
You may need to comment out the line in a file `/etc/modprobe.d/alsa-skl.conf`
```
blacklist snd_hda_intel
```

### Auto-rotation not working (#5)
While auto rotation is not working, you can rotate your screen by:

If you are in tablet_mode:
    - Use this android app: [azw413/ChromeOSRotate: Android App to rotate orientation on Chrome Tablets](https://github.com/azw413/ChromeOSRotate)

If you are not in tablet_mode:
    - `Ctrl+Shift+Reload` (`Ctrl+Shift+Super(Win)+F3`)

### Auto mode change into tablet_mode not working (#6)
While auto mode change is not working, you can manually change the mode by keyboard.

To do so, add a flag `--ash-debug-shortcuts` to your `/etc/chrome_dev.conf`,
then restart your ui `sudo restart ui`, after that, you can change the mode by `Ctrl+Alt+Shift+T`.

```bash
# mount root filesystem as writable
sudo mount / -o rw,remount
```

```bash
# Edit this file
sudo vim /etc/chrome_dev.conf
```

### Taking a screenshot using Pow+VolDown not working (#7)
While that function not working, you can take a screenshot without keyboard by
- Settings -> Device -> Stylus -> Show stylus tools in the shelf

and in the stylus tools, choose "Capture screen".
However, if you "Autohide shelf", the screenshot is taken before the shelf is completely hidden.
