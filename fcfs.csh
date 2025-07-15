#!/bin/csh



##################################################
# PROCESS AMOUNT SETUP
# - Decide if process data is taken dynamically (predefined)
#   or automatically (user input during runtime)
##################################################

while (1)
    echo "In which system do you want to take input?"
    echo "   1. Dynamically (enter processes one by one)"
    echo "   2. Fixed number of processes (equal to user-given amount)"
    echo ""

    while(1)
        echo -n "Select your choice : "
        set choice = $<

        if ( $choice !~ [1-2] ) then
            echo "Invalid Input! Please input either 1 or 2."
            ./wrong_alert.csh
            continue
        else
            break
        endif  
    end
    break
end





##################################################
# CREATE ARRAYS
# - process_list: Contains process IDs
# - arrival_list: Arrival times of processes
# - burst_list  : Burst times of processes
#
# CREATE VARIABLE
# - process     : Store the process amount
##################################################

set process_list = ()
set arrival_list = ()
set burst_list   = ()
set process = 0



##################################################
# INPUT SECTION
# - If dynamic, give process IDs
# - If automatic, generate process ID in sequencely and take arrival time, burst time from user
# - Check if process ID is duplicate ( for dynamic )
# - Store values in all 3 arrays
# - Display stored data for confirmation
##################################################


switch ( $choice )
    case 1:
        while (1)

            # PROCESS ID
            while (1)
                echo -n "Enter the process ID : "
                set process_id = $<

                # Validate using grep with safe quoting
                set is_numeric = `echo "$process_id" | grep -E '^[0-9]+$'`

                if ( "$is_numeric" == "" ) then
                    echo "Non-integer value is not allowed as process ID."
                    echo ""
                    ./wrong_alert.csh
                    continue
                else if ( $process_id == 0 ) then
                    echo "Zero is not allowed as process ID."
                    echo ""
                    ./wrong_alert.csh
                    continue
                endif


                @ i = 1
                @ check = 0
                while ( $i <= $#process_list )
                    if ( $process_id == $process_list[$i] ) then
                        echo "$process_id is already enlisted in the process list."
                        ./wrong_alert.csh
                        echo ""
                        @ check = 1
                        break
                    endif
                    @ i++
                end

                if ( $check == 0 ) then
                    set process_list = ( $process_list $process_id )
                    break
                endif
            end


            # For arrival time & burst time
            echo "$arrival_list" > /tmp/arrival_list.txt
            echo "$burst_list" > /tmp/burst_list.txt
            ./sub.csh $process_id


            set arrival_list = (`cat /tmp/arrival_list.txt`)
            set burst_list   = (`cat /tmp/burst_list.txt`)

            @ process++
            set tmp = "0"

            # CHECK FOR INPUT

            if ( $process > 1 ) then
                while (1)
                    echo -n "Do you want to add more ? 'y' for yes or 'n' for no : "
                    set tmp = $<

                    if ( $tmp !~ [nNyY] ) then
                        echo "Invalid input! Try again."
                        ./wrong_alert.csh
                    else
                        break
                    endif
                end
            endif

            if ( "$tmp" == "n" || "$tmp" == "N" ) then
                echo ""
                break
            endif
        end

        breaksw

    case 2:
        while (1) 
            echo -n "How many process in CPU ? "
            set process = $<

            # Validate using grep with safe quoting
            set is_numeric = `echo "$process" | grep -E '^[0-9]+$'`

            if ( "$is_numeric" == "" ) then
                echo "Non-integer value is not allowed as process amount."
                echo ""
                ./wrong_alert.csh
            else
                break
            endif
        end

        @ i = 1
        while ( $i <= $process )
            set process_list = ( $process_list $i )
            
            # For arrival time & burst time
            echo "$arrival_list" > /tmp/arrival_list.txt
            echo "$burst_list" > /tmp/burst_list.txt
            ./sub.csh $i


            set arrival_list = (`cat /tmp/arrival_list.txt`)
            set burst_list   = (`cat /tmp/burst_list.txt`)

            @ i++
        end
        
        breaksw
    default:
        echo "Invalid Input"
        breaksw
endsw


rm -f /tmp/arrival_list.txt /tmp/burst_list.txt


@ i = 1

echo "===================================================="
echo "|   Process ID   |  Arrival Time  |   Burst Time   |"
while ( $i <= $process )
    echo "----------------------------------------------------"
    printf "|      P%-8s |        %-7s |       %-8s |\n" $process_list[$i] $arrival_list[$i] $burst_list[$i]

    @ i++
end
echo "===================================================="






##################################################
# SORTING SECTION
# - Create temporary text file
# - Write process data with arrival time first
# - Sort based on arrival time
# - Store sorted output in variable
# - Remove temporary file
# - Reset original lists and fill with sorted values
##################################################

set temp_file = "/tmp/sorting_file$$.txt"
rm -f $temp_file

@ i = 1
while ( $i <= $process )
    echo $arrival_list[$i] $burst_list[$i] $process_list[$i] >> $temp_file
    @ i++
end



set sorted_file = `sort -n $temp_file`

rm -f $temp_file



set process_list = ()
set arrival_list = ()
set burst_list = ()

@ i = 1
while ( $i <= $#sorted_file )
    set arrival_list = ( $arrival_list $sorted_file[$i] )
    @ i++

    set burst_list = ( $burst_list $sorted_file[$i] )
    @ i++

    set process_list = ( $process_list $sorted_file[$i] )
    @ i++

end



##################################################
# PRE-ALGORITHM PHASE
# - Initialize:
#     waiting_list, turnaround_list, executing_list, completion_list
# - Set:
#     total_waiting = 0
#     total_turnaround = 0
#     current_time = 0
##################################################

set waiting_list = ()
set turnaround_list = ()
set executing_list = ()
set completion_list= ()

@ total_waiting = 0
@ total_turnaround = 0
@ current_time = 0




##################################################
# ALGORITHM LOGIC (FCFS)
# For each process:
# 1. Get arrival and burst from sorted lists
# 2. If current_time < arrival => CPU is idle (adjust current_time)
# 3. waiting_time = current_time - arrival
# 4. Save waiting time and add to total waiting
# 5. executing_time = current_time
# 6. current_time += burst_time
# 7. completion_time = current_time
# 8. turnaround_time = completion_time - arrival
# 9. Save turnaround time and add to total turnaround
##################################################

@ i = 1
while ( $i <= $process )
    set arrival = $arrival_list[$i]
    set burst = $burst_list[$i]



    if ( $current_time < $arrival ) then    
        @ waiting = $arrival - $current_time
        @ current_time = $arrival
    else
        @ waiting = $current_time - $arrival
    endif


    set waiting_list = ( $waiting_list $waiting )
    @ total_waiting += $waiting

    set executing = $current_time
    set executing_list = ( $executing_list $executing )

    @ current_time += $burst
    set completion_list = ( $completion_list $current_time )

    @ turnaround = $current_time - $arrival
    set turnaround_list = ( $turnaround_list $turnaround )
    @ total_turnaround += $turnaround

    @ i++

end





##################################################
# POST-ALGORITHM PHASE
# - Calculate:
#     average_waiting_time = total_waiting / total_processes
#     average_turnaround_time = total_turnaround / total_processes
##################################################

set average_waiting_time = `echo "scale=2; $total_waiting / $process" | bc`
set average_turnaround_time = `echo "scale=2; $total_turnaround / $process" | bc`




##################################################
# OUTPUT PHASE
# - Display:
#     Process ID
#     Executing Start Time
#     Completion Time
#     Waiting Time
#     Turnaround Time
# - Display average waiting and turnaround times
##################################################

@ i = 1
echo ""
echo ""
echo "==============================================================================================================="
echo "|      Process ID     |    Executing Time   |   Completion Time   |     Waiting Time    |   Turnaround Time   |"
while ( $i <= $process )
    echo "---------------------------------------------------------------------------------------------------------------"
    printf "|        P%-11s |          %-10s |          %-10s |          %-10s |          %-10s |\n" $process_list[$i] $executing_list[$i] $completion_list[$i] $waiting_list[$i] $turnaround_list[$i]

    @ i++
end
echo "==============================================================================================================="
echo ""

echo "Average Waiting Time    : $average_waiting_time ms"
echo "Average Turnaround Time : $average_turnaround_time ms"
echo ""


