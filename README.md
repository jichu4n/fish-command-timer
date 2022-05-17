fish-command-timer
==================
[FishShell](https://fishshell.com/) extension for printing timing information for each command executed.

Usage
-----
After the execution of each command, the script prints out the total
execution time (up to millisecond precision), followed by the current time. The
execution time is formatted to be human-readable; e.g., `2h 7m 42s301`.

Demo:

![Demo Screen-cap](https://github.com/jichu4n/bash-command-timer/raw/master/bash_command_timer_screenshot.gif)

Additionally, the script will export the total execution time (as a human-readable string, e.g., `42s027`) as `$CMD_DURATION_STR`. You can use this
variable in your subsequent prompt.

Requirements
------------
This script requires fish shell 2.2 or above. It should run pretty much out of
the box on modern Linux and Mac OS X systems. Please report any
incompatibilities [on GitHub](https://github.com/jichu4n/fish-command-timer/issues).

Installation
------------
1. Download [`conf.d/fish_command_timer.fish`](https://github.com/jichu4n/fish-command-timer/blob/master/conf.d/fish_command_timer.fish) and put it in `~/.config/fish/conf.d/` as per [Fish shell convention](https://fishshell.com/docs/current/index.html#initialization).
2. If the above doesn't work for you (perhaps because your custom settings overrides the extension), you could try sourcing it directly. Download [`conf.d/fish_command_timer.fish`](https://github.com/jichu4n/fish-command-timer/blob/master/conf.d/fish_command_timer.fish) and put it in `~/.config/fish/`, then add the following in your `~/.config/fish/config.fish` at the end:
   ```
   source ~/.config/fish/fish_command_timer.fish
   ```

That's it :)

Settings
--------
You can use the following options to tweak the behavior of the script. 
Put them in your `config.fish`. 
You can also modify them on-the-fly if you want the changes to only affect your current shell session.

* `set fish_command_timer_enabled`: Setting this variable to `0` disables
  printing of all timing and exit status information.
* `set fish_command_timer_status_enabled`: Setting this variable to `0`
  disables printing of exit status information.
* `set fish_command_timer_color blue`: The color to use for timing information.
  This should be a color string recognized by fish's [`set_color`](http://fishshell.com/docs/current/commands.html#set_color) command.
* `set fish_command_timer_success_color green`: The color of the last command's exit
  status if it was successful (i.e., `0`).
* `set fish_command_timer_fail_color red`: The color of the last command's exit
  status if it was not successful.
* `set fish_command_timer_time_format '%b %d %I:%M%p'`: The display format of
  the current time.  This is a strftime format string (see
  http://strftime.org/). If empty, the current time will not be printed.
* `set fish_command_timer_millis`: Whether to print timings to millisecond
  precision. If set to `0`, will print timings up to seconds.
* `set fish_command_timer_export_cmd_duration_str`: If set to `1`, will export
  the total command execution time string to `$CMD_DURATION_STR`, If set to `0`, the `$CMD_DURATION_STR` variable will not be exported.
* `set fish_command_timer_min_cmd_duration`: The minimum command duration (in
  milliseconds) that should trigger printing of command timing information.
  Commands that complete within the specified number of milliseconds will not
  trigger printing of command timing information.
  - Note that when `fish_command_timer_status_enabled` is set, commands that
    exit with a non-zero status will always trigger printing of command timing
    and exit status information even if they complete within
    `$fish_command_timer_min_cmd_duration`.
