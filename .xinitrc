export XCURSOR_THEME=BreezeX-RosePine-Linux
export XCURSOR_SIZE=24
xinput set-prop "ASUE140D:00 04F3:31B9 Touchpad" "libinput Tapping Enabled" 1 &
source /home/jwno/.local/venv/qtile/bin/activate
exec qtile start
