
# High DPI X11 Settings
We assume we have a monitor with
a resolution of 159x159 dots per inch (DPI).

See [archlinux](https://wiki.archlinux.org/title/HiDPI).

## Firefox
Based on a 96 dpi default scale 1,
the scale factor is `159 / 96 = 1.65`.
```
layout.css.devPixelsPerPx 1.65
```

See [archlinux](https://wiki.archlinux.org/title/HiDPI#Firefox).

### Disable Other Settings
```
browser.display.os-zoom-behavior 0
```

## Xresources
- [archlinux](https://wiki.archlinux.org/title/X_resources)

File ~/.Xresources
```
Xft.dpi: 159

! These might also be useful depending on your monitor and personal preference:
Xft.autohint: 0
! Xft.lcdfilter:  lcddefault
Xft.lcdfilter:  lcdnone
! Xft.hintstyle:  hintfull
! Xft.hintstyle:  hintmedium
Xft.hintstyle:  hintslight
! Xft.hintstyle:  hintnone
Xft.hinting: 1
Xft.antialias: 1
Xft.rgba: rgb
```

If you like to support better font rendering for old applications
like [DDD, this works quite well](https://begriffs.com/posts/2022-07-17-debugging-gdb-ddd.html#utf-8-rendering)
```
Ddd*renderTable: rt
Ddd*rt*fontType: FONT_IS_XFT
Ddd*rt*fontName: DejaVu Sans Mono
Ddd*rt*fontSize: 10
```

### Load/Merge
```
# Load
xrdb ~/.Xresources

# Merge
xrdb -merge ~/.Xresources
```

### Test
```
xrdb -query
xrdb -query -all
```

## xsettingsd (Gnome/GTK/GDK/...)
- [archlinux](https://wiki.archlinux.org/title/Xsettingsd)
- [codeberg](https://codeberg.org/derat/xsettingsd)

`Xft/DPI` is your DPI multiplied by 1024.

File ~/.config/xsettingsd/xsettingsd.conf
```
Gdk/UnscaledDPI 162816
Xft/DPI 162816
Xft/lcdfilter "lcdnone"
Xft/HintStyle "hintslight"
Xft/Hinting 1
Xft/Antialias 1
Xft/RGBA "rgb"
```

### Restart and Test
Restart
```
killall -HUP xsettingsd
```

Show values
```
dump_xsettings
```

