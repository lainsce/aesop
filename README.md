# ![icon](data/icon.png) Aesop

## The simplest PDF viewer around

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.lainsce.aesop)

[![Build Status](https://travis-ci.org/lainsce/aesop.svg?branch=master)](https://travis-ci.org/lainsce/aesop)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

![Screenshot](data/shot.png)

## Donations

Would you like to support the development of this app to new heights? Then:

[Be my backer on Patreon](https://www.patreon.com/lainsce)

## Dependencies

Please make sure you have these dependencies first before building.

```bash
granite
gtk+-3.0
meson
libsoup2.4
libjson-glib
```

## Building

Simply clone this repo, then:

```bash
meson build --prefix=/usr && cd build
sudo ninja install
```

## Arch Linux
Arch Linux users can find Aesop under the name [aesop-git](https://aur.archlinux.org/packages/aesop-git/) in the **AUR**:

`$ pikaur -S aesop-git`
