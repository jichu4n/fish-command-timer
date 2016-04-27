fish-command-timer
==================

fish shell extension for printing timing information for each command line
executed.

Usage
-----

After the execution of each command line, the script prints out the total
execution time (up to millisecond precision), followed by the current time. The
execution time is formatted to be human readable; e.g., `2h 7m 42s301`.

Demo:

![Demo Screen-cap](https://github.com/jichuan89/bash-command-timer/raw/master/bash_command_timer_screenshot.gif)

Requirements
------------

This script requires fish shell 2.2 or above. It should run pretty much out of
the box on modern Linux and Mac OS X systems. Please report any
incompatibilities on
[on GitHub](https://github.com/jichu4n/fish-command-timer/issues).

Installation
------------

To set up this extension, you can

1. Download `fish_command_timer.fish` somewhere, and add the following to your
   `~/.config/fish/config.fish` (replace with actual path where you saved the script):

   ```bash
   source ~/.fish_command_timer.fish
   ```

2. Alternatively, you can simply copy and paste the contents of
   `fish_command_timer.fish` into your `~/.config/fish/config.fish`.

That's it :)

Settings
--------

You can use the following options to tweak the behavior of the script. You can
either make the changes in-place (at the top of the script) or put them after
sourcing the script in your `config.fish`. You can also modify them on-the-fly if
you want the changes to only affect your current shell session.

* `set fish_command_timer_enabled`: Unsetting this variable with `set -e` disables
  this script.
* `set fish_command_timer_color blue`: The color of the output. This should be a
  color string recognized by fish's set_color command, as described
  [here](http://fishshell.com/docs/current/commands.html#set_color). If not set,
  the output will be in the default color.
* `set fish_command_timer_time_format '%b %d %I:%M%p'`: The display format of
  the current time.  This is a strftime format string (see
  http://strftime.org/). If empty, the current time will not be printed.
* `set fish_command_timer_millis`: Whether to print timings to millisecond
  precision. If unset, will print timings up to seconds.

