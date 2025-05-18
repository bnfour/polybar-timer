#!/bin/bash

### AUTHOR:         Johann Birnick (github: jbirnick), changes by bnfour
### PROJECT REPO:   https://github.com/bnfour/polybar-timer

#region "settings"

# return 0 to enable upstream "timer expires at" and "timer paused" notifications
notificationsEnabled () { return 123; }

#endregion

#region functions

now () { date --utc +%s; }

setVariables () {
  # if no external pid provided as an argument, use this script's own one
  if [ "$1" ]; then
    pid=$1
  else
    pid=$$
  fi

  path="/tmp/polybar-timer-$pid"
  notificationId=$(( 12345 + pid ))
}

killTimer () { rm -rf "$path" ; }
timerSet () { [ -e "$path/" ] ; }
timerPaused () { [ -f "$path/paused" ] ; }

timerExpiry () { cat "$path/expiry" ; }
timerLabelRunning () { cat "$path/label_running" ; }
timerLabelPaused () { cat "$path/label_paused" ; }
timerAction () { cat "$path/action" ; }

secondsLeftWhenPaused () { cat "$path/paused" ; }
minutesLeftWhenPaused () { echo $(( ( $(secondsLeftWhenPaused)  + 59 ) / 60 )) ; }
secondsLeft () { echo $(( $(timerExpiry) - $(now) )) ; }
minutesLeft () { echo $(( ( $(secondsLeft)  + 59 ) / 60 )) ; }

printExpiryTime () { notificationsEnabled && notify-send -u low -r $notificationId "Timer expires at $( date -d "$(secondsLeft) sec" +%H:%M)" || return 0 ;}
printPaused () { notificationsEnabled && notify-send -u low -r $notificationId "Timer paused" || return 0 ; }
removePrinting () { notificationsEnabled && notify-send -u low -r $notificationId -t 1 "" || return 0 ; }

updateTail () {
  # check whether timer is expired
  if timerSet
  then
    if { timerPaused && [ "$(minutesLeftWhenPaused)" -le 0 ] ; } || { ! timerPaused && [ "$(minutesLeft)" -le 0 ] ; }
    then
      eval "$(timerAction)" 2>/dev/null 1>/dev/null
      killTimer
      removePrinting
    fi
  fi

  # update output
  if timerSet
  then
    if timerPaused
    then
      echo "$(timerLabelPaused)$(minutesLeftWhenPaused)"
    else
      echo "$(timerLabelRunning)$(minutesLeft)"
    fi
  else
    echo "${STANDBY_LABEL}"
  fi
}

usage() {
    cat <<EOF
A script to create, start, and control a timer.
Designed for use within polybar. Check out https://github.com/bnfour/polybar-timer#example-configuration for an example.

Script usage: $0 [COMMAND] args ...

COMMAND:
  tail [label] [s]                          - Print the [label], followed by the time left on the timer, every [s] seconds.
                                              This may be used for the exec field in polybar.

The following commands alter the state of a tail script, identified by its PID [pid].
The PID is provided by polybar with %pid%.

  new [m] [rLabel] [pLabel] [action] [pid]  - Create a new timer with [m] minutes. Printed as "[rLabel|pLabel] [m]".
                                              [rLabel] is shown while the timer is running, and [pLabel] is shown while the timer is paused.
                                              The action will be executed when the timer expires.
  update [pid]                              - Update a running [tail] command.
  increase [s] [pid]                        - Increase the timer by [s] seconds if it exists.
  togglepause [pid]                         - Pause a running timer; Start a paused timer.
  cancel [pid]                              - Cancel a timer if it exists.
  help                                      - Print this help.

EOF
}

#endregion

#region main code

case $1 in
  tail)
    setVariables
    STANDBY_LABEL=$2

    trap updateTail USR1

    while true
      do
      updateTail
      sleep "${3}" &
      wait
    done
    ;;
  update)
    kill -USR1 $(pgrep --oldest --parent "${2}")
    ;;
  new)
    setVariables "${6}"
    killTimer
    mkdir "$path"
    echo "$(( $(now) + 60*${2} ))" > "$path/expiry"
    echo "${3}" > "$path/label_running"
    echo "${4}" > "$path/label_paused"
    echo "${5}" > "$path/action"
    printExpiryTime
    ;;
  increase)
    setVariables "${3}"
    if timerSet
    then
      if timerPaused
      then
        echo "$(( $(secondsLeftWhenPaused) + ${2} ))" > "$path/paused"
      else
        echo "$(( $(timerExpiry) + ${2} ))" > "$path/expiry"
        printExpiryTime
      fi
    else
      exit 1
    fi
    ;;
  cancel)
    setVariables "${2}"
    killTimer
    removePrinting
    ;;
  togglepause)
    setVariables "${2}"
    if timerSet
    then
      if timerPaused
      then
        echo "$(( $(now) + $(secondsLeftWhenPaused) ))" > "$path/expiry"
        rm -f "$path/paused"
        printExpiryTime
      else
        secondsLeft > "$path/paused"
        rm -f "$path/expiry"
        printPaused
      fi
    else
      exit 1
    fi
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo -e "For usage type: $0 help\n"
    echo "Please read the manual at https://github.com/bnfour/polybar-timer ."
    ;;
esac

#endregion
