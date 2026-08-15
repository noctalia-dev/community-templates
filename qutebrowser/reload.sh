#!/bin/sh
pgrep -x qutebrowser >/dev/null && qutebrowser :config-source
