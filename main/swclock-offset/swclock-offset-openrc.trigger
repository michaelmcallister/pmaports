#!/bin/sh

# Run after the whole transaction: postmarketos-base may enable hwclock
# after swclock-offset's post-install has already replaced it.
rc-update -q del hwclock boot 2>/dev/null || true
exit 0
