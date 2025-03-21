{
  pkgs,
  lib,
  ...
}:
# Power Menu that uses Rofi. Can be modified to have multiple actions, for example stopping MPD before Suspend
pkgs.writeShellScriptBin "rofi-powermenu" ''
  ## Author : Aditya Shakya (adi1090x)
  ## Github : @adi1090x
  #
  ## Rofi   : Power Menu
  #

  # Current Theme
  dir="~/.local/share/rofi/themes"
  theme='system'

  # CMDs
  uptime="`${lib.getExe' pkgs.procps "uptime"} -p | sed -e 's/up //g'`"
  host=`hostname`

  # Options
  shutdown=' Shutdown'
  reboot='󰑓 Reboot'
  lock=' Lock'
  suspend=' Suspend'
  logout='󰿅 Logout'
  yes='Yes'
  no='No'

  # Rofi CMD
  rofi_cmd() {
    rofi -dmenu \
      -p "$host" \
      -mesg "Uptime: $uptime" \
      -theme $dir/$theme.rasi
  }

  # Confirmation CMD
  confirm_cmd() {
  	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 250px;}' \
  		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
  		-theme-str 'listview {columns: 2; lines: 1;}' \
  		-theme-str 'element-text {horizontal-align: 0.5;}' \
  		-theme-str 'textbox {horizontal-align: 0.5;}' \
  		-dmenu \
  		-p 'Confirmation' \
  		-mesg 'Are you Sure?' \
  		-theme $dir/$theme.rasi
  }

  # Ask for confirmation
  confirm_exit() {
  	echo -e "$yes\n$no" | confirm_cmd
  }

  # Pass variables to rofi dmenu
  run_rofi() {
  	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
  }

  # Execute Command
  run_cmd() {
  	selected="$(confirm_exit)"
  	if [[ "$selected" == "$yes" ]]; then
  		if [[ $1 == '--shutdown' ]]; then
  			mpc -q pause
  			systemctl poweroff
  		elif [[ $1 == '--reboot' ]]; then
  			mpc -q pause
  			systemctl reboot
  		elif [[ $1 == '--suspend' ]]; then
  			mpc -q pause
        #	amixer set Master mute
  			systemctl suspend
  		elif [[ $1 == '--logout' ]]; then
  			niri msg action quit
  		fi
  	else
  		exit 0
  	fi
  }

  # Actions
  chosen="$(run_rofi)"
  case $chosen in
      $shutdown)
  		run_cmd --shutdown
          ;;
      $reboot)
  		run_cmd --reboot
          ;;
      $lock)
      hyprlock
          ;;
      $suspend)
  		run_cmd --suspend
          ;;
      $logout)
  		run_cmd --logout
          ;;
  esac
''
