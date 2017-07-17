# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                             #
#    Copyright (C) 2016 Chuan Ji <jichu4n@gmail.com>                          #
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
if date --date='@0' '+%s' > /dev/null ^ /dev/null
  # Linux.
  function fish_command_timer_print_time
    date --date="@$argv[1]" +"$fish_command_timer_time_format"
  end
else if date -r 0 '+%s' > /dev/null ^ /dev/null
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

# Computes whether the postexec hooks should compute command duration.
function fish_command_timer_compute
  begin
    set -q fish_command_timer_enabled; and \
    [ "$fish_command_timer_enabled" -ne 0 ]
  end; or \
  begin
    set -q fish_command_timer_export_cmd_duration_str; and \
    [ "$fish_command_timer_export_cmd_duration_str" -ne 0 ]
  end
end

# The fish_postexec event is fired after executing a command line.
function fish_command_timer_postexec -e fish_postexec
  if not fish_command_timer_compute
    return
  end
  set -l command_end_time (date '+%s')

  set -l SEC 1000
  set -l MIN 60000
  set -l HOUR 3600000
  set -l DAY 86400000

  set -l num_days (math "$CMD_DURATION / $DAY")
  set -l num_hours (math "$CMD_DURATION % $DAY / $HOUR")
  set -l num_mins (math "$CMD_DURATION % $HOUR / $MIN")
  set -l num_secs (math "$CMD_DURATION % $MIN / $SEC")
  set -l num_millis (math "$CMD_DURATION % $SEC")
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
  set -l num_millis_pretty ''
  if begin
      set -q fish_command_timer_millis; and \
      [ "$fish_command_timer_millis" -ne 0 ]
     end
    set num_millis_pretty (printf '%03d' $num_millis)
  end
  set time_str {$time_str}{$num_secs}s{$num_millis_pretty}
  if begin
      set -q fish_command_timer_export_cmd_duration_str; and \
      [ "$fish_command_timer_export_cmd_duration_str" -ne 0 ]
     end
    set CMD_DURATION_STR "$time_str"
  end

  if begin
       not set -q fish_command_timer_enabled; or \
       not [ "$fish_command_timer_enabled" -ne 0 ]
     end
    return
  end

  set -l now_str (fish_command_timer_print_time $command_end_time)
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

