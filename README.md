# riemann-nut

Submits nut information to riemann.

## Get started

```
gem install riemann-nut
riemann-nut --ups upsa@192.168.0.5 upsb@192.168.0.5 upsc@192.168.0.6
```

## Example metrics

Syntax: `<service>: <metric> (<state>)\n<description>\n`

```
ups@192.168.100.1 battery charge: 100 (ok)
100 %
ups@192.168.100.1 battery voltage: 13.5 (ok)
13.5 V
ups@192.168.100.1 input voltage: 232.0 (ok)
232.0 V
ups@192.168.100.1 ups alarm: (critical)
Replace battery! No battery installed!
ups@192.168.100.1 ups load: 13 (ok)
13 W
ups@192.168.100.1 ups status: (critical)
ALARM OL RB
```
