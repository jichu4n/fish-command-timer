# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                             #
#    Copyright (C) 2016 Chuan Ji <jichuan89@gmail.com>                        #
#                                                                             #
#    Licensed under the Apache License, Version 2.0 (the "License");          #
#    you may not use this file except in compliance with the License.         #
#    You may obtain a copy of the License at                                  #
#                                                                             #
#     http://www.apache.org/licenses/LICENSE-2.0                              #
#                                                                             #
#    Unless required by applicable law or agreed to in writing, software      #
#    distributed under the License is distributed on an "AS IS" BASIS,        #
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. #
#    See the License for the specific language governing permissions and      #
#    limitations under the License.                                           #
#                                                                             #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# A fish shell script for printing execution time for each command.
#
# For the most up-to-date version, as well as further information and
# installation instructions, please visit the GitHub project page at
#     https://github.com/jichuan89/fish-command-timer
#
# Requires fish 2.2 or above.

# SETTINGS
# ========
#
# Whether to enable the command timer by default.
#
# To temporarily disable the printing of timing information, type the following
# in a session:
#     set fish_command_timer_enabled 0
# To re-enable:
#     set fish_command_timer_enabled 1
if not set -q fish_command_timer_enabled
  set fish_command_timer_enabled 1
end

# The color of the output.
#
# This should be a color string accepted by fish's set_color command, as
# described here:
#
#     http://fishshell.com/docs/current/commands.html#set_color
#
# If empty, disable colored output. Set it to empty if your terminal does not
# support colors.
if not set -q fish_command_timer_color
  set fish_command_timer_color blue
end

# The display format of the current time.
#
# This is a strftime format string (see http://strftime.org/). To tweak the
# display format of the current time, change the following line to your desired
# pattern.
#
# If empty, disables printing of current time.
if not set -q fish_command_timer_time_format
  set fish_command_timer_time_format '%b %d %I:%M%p'
end

# Whether to print command timings up to millisecond precision.
#
# If set to 0, will print up to seconds precision.
if not set -q fish_command_timer_millis
  set fish_command_timer_millis 1
end


# IMPLEMENTATION
# ==============

# fish_command_timer_get_ts:
#
# Command to print out the current time in nanoseconds. This is required
# because the "date" command in OS X and BSD do not support the %N sequence.
#
# fish_command_timer_print_time:
#
# Command to print out a timestamp using fish_command_timer_time_format. The
# timestamp should be in seconds. This is required because the "date" command in
# Linux and OS X use different arguments to specify the timestamp to print.
if date +'%N' | grep -qv 'N'
  function fish_command_timer_get_ts
    date '+%s%N'
  end
  function fish_command_timer_print_time
    date --date="@$argv[1]" +"$fish_command_timer_time_format"
  end
else if type gdate > /dev/null ^ /dev/null; and gdate +'%N' | grep -qv 'N'
  function fish_command_timer_get_ts
    gdate '+%s%N'
  end
  function fish_command_timer_print_time
    gdate --date="@$argv[1]" +"$fish_command_timer_time_format"
  end
else if type perl > /dev/null ^ /dev/null
  function fish_command_timer_get_ts
    perl -MTime::HiRes -e 'printf("%d",Time::HiRes::time()*1000000000)'
  end
  function fish_command_timer_print_time
    date -r "$argv[1]" +"$fish_command_timer_time_format"
  end
else
  echo 'No compatible date, gdate or perl commands found, not enabling fish command timer'
  set fish_command_timer_enabled 0
end

# fish_command_timer_strlen:
#
# Command to print out the length of a string. This is required because the expr
# command behaves differently on Linux and OS X. On fish 2.3+, we will use the
# "string" builtin.
if type string > /dev/null ^ /dev/null
  function fish_command_timer_strlen
    string length "$argv[1]"
  end
else if expr length + "1" > /dev/null ^ /dev/null
  function fish_command_timer_strlen
    expr length + "$argv[1]"
  end
else if type wc > /dev/null ^ /dev/null; and type tr > /dev/null ^ /dev/null
  function fish_command_timer_strlen
    echo -n "$argv[1]" | wc -c | tr -d ' '
  end
else
  echo 'No compatible string, expr, or wc commands found, not enabling fish command timer'
  set fish_command_timer_enabled 0
end

if not set -q fish_command_timer_start_time
  set fish_command_timer_start_time
end

# The fish_preexec event is fired before executing a command line.
function -e fish_preexec fish_command_timer_preexec
  if begin
       not set -q fish_command_timer_enabled; or \
       not [ "$fish_command_timer_enabled" -ne 0 ]
     end
    return
  end
  set fish_command_timer_start_time (fish_command_timer_get_ts)
end

# The fish_postexec event is fired after executing a command line.
function -e fish_postexec fish_command_timer_postexec
  if begin
       not set -q fish_command_timer_enabled; or \
       not [ "$fish_command_timer_enabled" -ne 0 ]
     end
    return
  end
  if [ -z "$fish_command_timer_start_time" ]
    return
  end

  set -l MSEC 1000000
  set -l SEC (math "1000 * $MSEC")
  set -l MIN (math "60 * $SEC")
  set -l HOUR (math "60 * $MIN")
  set -l DAY (math "24 * $HOUR")

  set -l command_start_time $fish_command_timer_start_time
  set -l command_end_time (fish_command_timer_get_ts)
  set -l command_time (math "$command_end_time - $command_start_time")
  set -l num_days (math "$command_time / $DAY")
  set -l num_hours (math "$command_time % $DAY / $HOUR")
  set -l num_mins (math "$command_time % $HOUR / $MIN")
  set -l num_secs (math "$command_time % $MIN / $SEC")
  set -l num_msecs (math "$command_time % $SEC / $MSEC")
  set -l time_str ""
  if [ $num_days -gt 0 ]
    set time_str {$time_str}{$num_days}"d "
  end
  if [ $num_hours -gt 0 ]
    set time_str {$time_str}{$num_hours}"h "
  end
  if [ $num_mins -gt 0 ]
    set time_str {$time_str}{$num_mins}"m "
  end
  set -l num_msecs_pretty ''
  if begin
      set -q fish_command_timer_millis; and \
      [ "$fish_command_timer_millis" -ne 0 ]
     end
    set num_msecs_pretty (printf '%03d' $num_msecs)
  end
  set time_str {$time_str}{$num_secs}s{$num_msecs_pretty}

  set -l now_str (fish_command_timer_print_time (math "$command_end_time / $SEC"))
  set -l output_str
  if [ -n "$now_str" ]
    set output_str "[ $time_str | $now_str ]"
  else
    set output_str "[ $time_str ]"
  end
  set -l output_str_colored
  if begin
       set -q fish_command_timer_color; and \
       [ -n "$fish_command_timer_color" ]
     end
    set output_str_colored (set_color $fish_command_timer_color)"$output_str"(set_color normal)
  else
    set output_str_colored "$output_str"
  end
  set -l output_str_length (fish_command_timer_strlen "$output_str")

  # Move to the end of the line. This will NOT wrap to the next line.
  echo -ne "\033["{$COLUMNS}"C"
  # Move back (length of output_str) columns.
  echo -ne "\033["{$output_str_length}"D"
  # Finally, print output.
  echo -e "$output_str_colored"
end

