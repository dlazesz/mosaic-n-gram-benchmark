#!/bin/bash
# Original code: https://stackoverflow.com/questions/54920113/calculate-average-execution-time-of-a-program-using-bash/54940448#54940448

avg_time_alt() {
    shopt -s expand_aliases
    local -i n=$1
    local foo real sys user
    shift
    (($# > 0)) || return;
    # Alias command to he able to handle commands containing pipes
    alias cmd="$*"
    { read -r foo real; read -r foo user; read -r foo sys ;} < <(
        { time -p for((;n--;)){ cmd &>/dev/null ;} ;} 2>&1
    )
    # Replace decimal separator for bc and restore it if needed
    if [[ $(locale decimal_point) != "." ]]; then
        alias bc="sed 's/,/./g' | bc | sed 's/\./,/g'"
    fi
    printf "real: %f\nuser: %f\nsys : %f\n" $(echo "scale=5;$real/$n;$user/$n;$sys/$n;" | bc )
}

avg_time_alt "$@"
