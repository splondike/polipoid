#!/system/bin/sh

# Wraps the polipo binary, passes all command line arguments directly to the binary.
# The purpose is to:
# 1. Shut down the proxy when the stdin stream is closed, this indicates the parent
#    service is dead.
# 2. Get the pid of the binary (without java reflection hacks). The pid is output
#    as the first line of stdout.
#
# Note: When editing be careful about what shell utilities you use, android doesn't
#       come with very many (no busybox by default remember!). Check on the emulator.

script_pid=$$
polipo_args=$@
polipo_pid=0
run_polipo() {
  ./polipo $polipo_args &
  polipo_pid=$!
  echo $polipo_pid
  wait $polipo_pid
  kill $script_pid 2> /dev/null > /dev/null
}

run_polipo &
read line # Wait for the parent process to die
kill $polipo_pid 2> /dev/null > /dev/null
