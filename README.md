# polybar-timer

This script implements a **simple** and **customizable** timer for your bar.

This fork (ab)uses polybar's `%pid%` to allow multiple timers running independently (I don't often need multiple timers running, but when I do...), among other changes.

- specify a command to execute when the timer expires (e.g. notify-send, shell script, ...)
- interactive:
  * e.g. scroll to increase / decrease timer
  * click to start predefined timers
  * while changing a timer a notification displays when the timer will expire (optional, disabled by default in this fork)
  * pause timer
- different icons for different kind of timers

![screenshot set timer](screenshots/setTimer.gif) (set a timer)

![screenshot cancel timer](screenshots/cancelTimer.gif) (cancel a timer)

![screenshot set predefined timer](screenshots/predefinedTimer.gif) (start predefined timer)

![screenshot set predefined timer 2 and increase it](screenshots/predefinedTimer2.gif) (start other predefined timer and increase it)

![screenshot see expiry time](screenshots/expiryTimePreview.gif) (watch expiry time when you change a timer)

> [!NOTE]   
> These notifications are disabled by default in this fork.  
> Modify `notificationsEnabled` to return 0 to re-enable them.

Even though the repo is named [`polybar-timer`](#), it is a general script and you can use it for every bar.
In particular, if you use [**waybar**](https://github.com/Alexays/Waybar), then you can find a waybar-specific implementation of this timer [here](https://github.com/jbirnick/waybar-timer).
You can **customize behaviour and appearance in a simple way**.

Use cases: pomodoro timer, self-reminder when next meeting begins, tea/pasta timer, ...

## Dependencies

This script works perfectly **without any dependencies**.

## Installation

1. Download `polybar-timer.sh` from this repo.
2. Make it executable. (`chmod +x polybar-timer.sh`)
3. Copy-paste the [example configuration](#example-configuration) from below into your polybar config.
4. Customize. (see [Customization section](#customization))

## Example Configuration

> [!IMPORTANT]  
> Please note that this fork requires passing `%pid%` as last argument to every command except `tail` (and `help`, of course)

```ini
[module/timer]

type = custom/script

exec = /path/to/polybar-timer.sh tail 'TIMER' 5
tail = true

click-left = /path/to/polybar-timer.sh new 25 'Pomo session' 'Paused' 'notify-send "Session finished"' %pid% ; /path/to/polybar-timer.sh update %pid%
click-middle = /path/to/polybar-timer.sh cancel %pid% ; /path/to/polybar-timer.sh update %pid%
click-right = /path/to/polybar-timer.sh togglepause %pid% ; /path/to/polybar-timer.sh update %pid%
scroll-up = /path/to/polybar-timer.sh increase 60 %pid% || /path/to/polybar-timer.sh new 1 'TIMER' 'PAUSED' 'notify-send -u critical "Timer expired."' %pid% ; /path/to/polybar-timer.sh update %pid%
scroll-down = /path/to/polybar-timer.sh increase -60 %pid% ; /path/to/polybar-timer.sh update %pid%
```

> [!NOTE]  
> This fork was created to support multiple independent timers. Just use the module name (`timer` in example config) multiple times in `modules-{left,center,right}` in polybar's config.

## Customization

The example configuration implements a 25min "pomodoro session" timer with left click, pausing with right click, canceling with middle click, and a normal timer by just scrolling up from the standby mode.

You can customize the different strings, numbers and actions to your own flavor and needs. To understand what the commands do and to implement some different behaviour see the [documentation](#documentation).

If you want to do some really specific stuff and add some functionality, just edit the script. It is really simple. Just take your 10 minutes to understand what it does and then customize it.

## Documentation
Notation: `<...>` are necessary arguments. `[...=DEFAULTVALUE]` are optional arguments,
and if you do not specify them their `DEFAULTVALUE` is used.

If want to understand or edit the script, I highly recommend to run a *tail process* (see below) in a terminal window without any bar.
This way you will see what the bar sees
and you will understand how the updates work.

You can call the script with the following arguments:

- #### `tail <STANDBY_LABEL> <SECONDS>`
  This is the command which you want to put in your polybar `exec` field.
  It runs an infinite loop that calls the [`update`](#update-pid) routine every `SECONDS` seconds.
  We will call the process which runs this `tail` routine the *tail process*.

- #### `update <PID>`
  This routine is resposible for updating the output (i.e. what you see on the bar) and for handling the `ACTION` when the timer expires.
  It is executed automatically inside the tail process every few seconds.
  However, you will most probably want to also trigger it manually (in addition to the regular updates) just after you have
  just executed some of the commands below. For example, if you have
  created a timer with [`new`](#new-minutes-timer_label-action), you want to call [`update`](#update-pid) on the tail process right after. `PID` needs to be the pid of the tail process.
  (this is [provided by polybar with `%pid%`](https://github.com/polybar/polybar/wiki/Module:-script#examples))<br>
  The update routine (triggered automatically every few seconds and whenever you call [`update`](#update-pid)) does the following:
  1. If there is a timer running and its expiry time is <= now, then it executes `ACTION` and kills the timer.
  2. It prints the current output. This is either `<TIMER_LABEL><minutes left>` if there is a timer running or `<STANDBY_LABEL>` if no timer is running.

These were the basic commands to handle the technical side. Now with the
following commands you can control the timer. If you want the bar to
to update immediately after a change, you should call [`update`](#update-pid) right after, for example
`polybar-timer.sh increase 60 <pid of tail process> ; polybar-timer.sh update <pid of tail process>'`.

> [!IMPORTANT]  
> In this fork, the following commands also require the tail process' PID to be passed.

<!-- TODO i guess with pid going after action it's not optional anymore, so it shouldn't have a default value-->
- #### `new <MINUTES> <TIMER_LABEL_RUNNING> <TIMER_LABEL_PAUSED> <ACTION=""> <PID>`
  1. If there is a timer already running this timer gets killed.
  2. Creates a timer of length `MINUTES` minutes and `TIMER_LABEL_RUNNING` as its
  label and sets its action to `ACTION`. (`ACTION` will be executed once the timer expires.) If this timer gets paused at some point, the label will be replaced by `TIMER_LABEL_PAUSED`.

- #### `increase <SECONDS> <PID>`
  If there is no timer set, nothing happens and it exits with 1.
  If there is a timer set, it is extended by `SECONDS` seconds. `SECONDS` can also be negative, in which case it shortens the timer. Then it exits
  with 0.

- #### `togglepause <PID>`
  If there is no timer set at all, it exits with 1. If there is a timer running, the timer gets paused and it exits with 0. If there is a timer set which is already paused, the timer gets resumed and it exits with 0.

- #### `cancel <PID>`
  If there is a timer running, the timer gets canceled. The `ACTION` will _not_ be
  executed.

## Tips & Tricks

Note, when there is no timer active, then [`increase`](#increase-seconds) does nothing.
So you might want to use the following command as a replacement for [`increase`](#increase-seconds).
```
polybar-timer.sh increase 60 %pid% || polybar-timer.sh new 1 'mytimer' 'paused' 'notify-send "Timer expired."' %pid%
```
It increases the existing timer if it's active, and creates a timer with label
"mytimer" of lengths 1 minute if there is no timer currently running.
So now e.g. scrolling up also does something when there is no timer active - it starts a new timer!
