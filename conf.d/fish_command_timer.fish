# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                             #
#    Copyright (C) 2016-2020 Chuan Ji <chuan@jichu4n.com>                     #
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
#     https://github.com/jichu4n/fish-command-timer
#
# Requires fish 2.2 or above.

# SETTINGS
# ========
#
# Whether to enable the command timer by default.
#
# To temporarily disable the command timer, type the following
# in a session:
#     set fish_command_timer_enabled 0
# To re-enable:
#     set fish_command_timer_enabled 1
if not set -q fish_command_timer_enabled
  set fish_command_timer_enabled 1
end
# Whether to display the exit status of the previous command.
if not set -q fish_command_timer_status_enabled
  set fish_command_timer_status_enabled 0
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
# Similarly, the color to use for displaying success and failure exit statuses.
if not set -q fish_command_timer_success_color
  set fish_command_timer_success_color green
end
if not set -q fish_command_timer_fail_color
  set fish_command_timer_fail_color $fish_color_status
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

# Whether to export the duration string as a shell variable.
#
# When set, this will export the duration string as an environment variable
# called $CMD_DURATION_STR.
if not set -q fish_command_timer_export_cmd_duration_str
  set fish_command_timer_export_cmd_duration_str 1
end
if begin
     set -q fish_command_timer_export_cmd_duration_str; and \
     [ "$fish_command_timer_export_cmd_duration_str" -ne 0 ]
   end
  set CMD_DURATION_STR
end

# The minimum command duration that should trigger printing of command timings,
# in milliseconds.
#
# When set to a non-zero value, commands that finished within the specified
# number of milliseconds will not trigger printing of command timings.
if not set -q fish_command_timer_min_cmd_duration
  set fish_command_timer_min_cmd_duration 0
end


# IMPLEMENTATION
# ==============

# fish_command_timer_get_ts:
#
# Command to print out the current time in seconds.
#
# fish_command_timer_print_time:
#
# Command to print out a timestamp using fish_command_timer_time_format. The
# timestamp should be in seconds. This is required because the "date" command in
# Linux and OS X use different arguments to specify the timestamp to print.
if date --date='@0' '+%s' > /dev/null 2> /dev/null
  # Linux.
  function fish_command_timer_print_time
    date --date="@$argv[1]" +"$fish_command_timer_time_format"
  end
else if date -r 0 '+%s' > /dev/null 2> /dev/null
  # macOS / BSD.
  function fish_command_timer_print_time
    date -r "$argv[1]" +"$fish_command_timer_time_format"
  end
else
  echo 'No compatible date commands found, not enabling fish command timer'
  set fish_command_timer_enabled 0
end

# fish_command_timer_strlen:
#
# Command to print out the length of a string. This is required because the expr
# command behaves differently on Linux and OS X. On fish 2.3+, we will use the
# "string" builtin.
if type string > /dev/null 2> /dev/null
  function fish_command_timer_strlen
    string length "$argv[1]"
  end
else if expr length + "1" > /dev/null 2> /dev/null
  function fish_command_timer_strlen
    expr length + "$argv[1]"
  end
else if type wc > /dev/null 2> /dev/null; and type tr > /dev/null 2> /dev/null
  function fish_command_timer_strlen
    echo -n "$argv[1]" | wc -c | tr -d ' '
  end
else
  echo 'No compatible string, expr, or wc commands found, not enabling fish command timer'
  set fish_command_timer_enabled 0
end

# Computes whether the postexec hooks should compute command duration.
function fish_command_timer_should_compute
  begin
    set -q fish_command_timer_enabled; and \
    [ "$fish_command_timer_enabled" -ne 0 ]
  end; or \
  begin
    set -q fish_command_timer_export_cmd_duration_str; and \
    [ "$fish_command_timer_export_cmd_duration_str" -ne 0 ]
  end
end

# Computes the command duration string (e.g. "3m5s016").
function fish_command_timer_compute_cmd_duration_str
  set -l SEC 1000
  set -l MIN 60000
  set -l HOUR 3600000
  set -l DAY 86400000

  set -l num_days (math -s0 "$CMD_DURATION / $DAY")
  set -l num_hours (math -s0 "$CMD_DURATION % $DAY / $HOUR")
  set -l num_mins (math -s0 "$CMD_DURATION % $HOUR / $MIN")
  set -l num_secs (math -s0 "$CMD_DURATION % $MIN / $SEC")
  set -l num_millis (math -s0 "$CMD_DURATION % $SEC")
  set -l cmd_duration_str ""
  if [ $num_days -gt 0 ]
    set cmd_duration_str {$cmd_duration_str}{$num_days}"d "
  end
  if [ $num_hours -gt 0 ]
    set cmd_duration_str {$cmd_duration_str}{$num_hours}"h "
  end
  if [ $num_mins -gt 0 ]
    set cmd_duration_str {$cmd_duration_str}{$num_mins}"m "
  end
  set -l num_millis_pretty ''
  if begin
      set -q fish_command_timer_millis; and \
      [ "$fish_command_timer_millis" -ne 0 ]
     end
    set num_millis_pretty (printf '%03d' $num_millis)
  end
  set cmd_duration_str {$cmd_duration_str}{$num_secs}s{$num_millis_pretty}
  echo $cmd_duration_str
end

# The fish_postexec event is fired after executing a command line.
function fish_command_timer_postexec -e fish_postexec
  set -l last_status $status
  set -l command_end_time (date '+%s')

  if not fish_command_timer_should_compute
    return
  end

  set -l cmd_duration_str (fish_command_timer_compute_cmd_duration_str)
  if begin
      set -q fish_command_timer_export_cmd_duration_str; and \
      [ "$fish_command_timer_export_cmd_duration_str" -ne 0 ]
     end
    set CMD_DURATION_STR "$cmd_duration_str"
  end

  if not begin
      set -q fish_command_timer_enabled; and \
      [ "$fish_command_timer_enabled" -ne 0 ]
      end
    return
  end
  if set -q fish_command_timer_min_cmd_duration; and \
      [ "$fish_command_timer_min_cmd_duration" -gt "$CMD_DURATION" ]; and begin
        [ "$last_status" -eq 0 ]; or \
        not set -q fish_command_timer_status_enabled; or \
        [ "$fish_command_timer_status_enabled" -eq 0 ]
      end
    return
  end


  # Compute timing string (e.g. [ 1s016 | Oct 01 11:11PM ])
  set -l timing_str
  set -l now_str (fish_command_timer_print_time $command_end_time)
  if [ -n "$now_str" ]
    set timing_str "[ $cmd_duration_str | $now_str ]"
  else
    set timing_str "[ $cmd_duration_str ]"
  end
  set -l timing_str_length (fish_command_timer_strlen "$timing_str")

  # Compute timing string with color.
  set -l timing_str_colored
  if begin
       set -q fish_command_timer_color; and \
       [ -n "$fish_command_timer_color" ]
     end
    set timing_str_colored (set_color $fish_command_timer_color)"$timing_str"(set_color normal)
  else
    set timing_str_colored "$timing_str"
  end

  # Compute status string (e.g. [ SIGINT ])
  set -l status_str ""
  if begin
      set -q fish_command_timer_status_enabled; and \
      [ "$fish_command_timer_status_enabled" -ne 0 ]
     end
    set -l signal (__fish_status_to_signal $last_status)
    set status_str "[ $signal ]"
  end
  set -l status_str_length (fish_command_timer_strlen "$status_str")

  # Compute status string with color.
  set -l status_str_colored
  if begin
      [ $last_status -eq 0 ]; and \
      set -q fish_command_timer_success_color; and \
      [ -n "$fish_command_timer_success_color" ]
      end
    set status_str_colored (set_color $fish_command_timer_success_color)"$status_str"(set_color normal)
  else if begin
      [ $last_status -ne 0 ]; and \
      set -q fish_command_timer_fail_color; and \
      [ -n "$fish_command_timer_fail_color" ]
      end
    set status_str_colored (set_color --bold $fish_command_timer_fail_color)"$status_str"(set_color normal)
  else
    set status_str_colored "$status_str"
  end

  # Combine status string and timing string.
  set -l output_length (math $timing_str_length + $status_str_length + 1)

  # Move to the end of the line. This will NOT wrap to the next line.
  echo -ne "\033["{$COLUMNS}"C"
  # Move back output_length columns.
  echo -ne "\033["{$output_length}"D"
  # Finally, print output.
  echo -e "$status_str_colored $timing_str_colored"
end

