#!/bin/csh

set arrival_list = (`cat /tmp/arrival_list.txt`)
set burst_list = (`cat /tmp/burst_list.txt`)
set process_id = $argv[1]
set arrival = ""
set burst = ""


# ARRIVAL TIME
while (1)
    echo -n "Enter the arrival time for proces id $process_id : "
    set arrival = $<

    # Validate using grep with safe quoting
    set is_numeric = `echo "$arrival" | grep -E '^[0-9]+$'`

    if ( "$is_numeric" == "" ) then
        echo "Non-integer value is not allowed as arrival time."
        echo ""
        ./wrong_alert.csh
    else
        set arrival_list = ( $arrival_list $arrival )
        break
    endif
end


# BURST TIME
while (1)
    echo -n "Enter the burst time for process id $process_id  : "
    set burst = $<

    # Validate using grep with safe quoting
    set is_numeric = `echo "$burst" | grep -E '^[0-9]+$'`

    if ( "$is_numeric" == "" ) then
        echo "Non-integer value is not allowed as burst time."
        echo ""
        ./wrong_alert.csh
    else
        set burst_list = ( $burst_list $burst )
        break
    endif
end


echo "$arrival_list" > /tmp/arrival_list.txt
echo "$burst_list" > /tmp/burst_list.txt


echo ""
echo "Process ID $process_id is successfully added into the list with arrival time ($arrival) and burst time ($burst)."
echo ""

