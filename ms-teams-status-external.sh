#! /bin/sh

#####################################################################################
#Script Name	:ms-teams-status-external.sh
#Description	:Read your Microsoft Teams meeting status and send it to Home Assistant
#Author       :Robert Drinovac
#GitHub       :https://www.github.com/RobertD502/TeamsStatusMacOS
#License      :MIT
#version      :0.2
#####################################################################################

teams_version="Old | New" # Set this to EITHER "Old" or "New" depending on the teams version you are using (See GitHub documentation)
webhook_url="YOUR_WEBHOOK" # Make sure your webhook url is inside quotation marks
previous_state_file=~/Documents/Teams_Status/previous_state.txt
powerd_log_file=~/Documents/Teams_Status/powerd_log.txt

#For first time usage, make sure previous state file is created
if [ ! -f "$previous_state_file" ]; then
      echo "previous_state: Unknown" > $previous_state_file
fi

# Handle New Teams version
if [ "$teams_version" == "New" ]; then
      # Fetch 30 min of powerd process' logs and locate event messages
      # related to MS Teams call.
      log show --style syslog --last 30m --process "powerd" > $powerd_log_file
      teams_event=$(grep "Microsoft Teams Call in progress" "$powerd_log_file" | tail -1)
      # Determine the meeting status based on the most recent status in powerd log
      if [ -n "$teams_event" ]; then
            in_meeting_count=$(printf %s "$teams_event" | grep -Fo "Created" | wc -l)
            left_meeting_count=$(printf %s "$teams_event" | grep -Fo "Released" | wc -l)
            if [ "$in_meeting_count" -eq 1 ]; then
                  meeting_status="In meeting"
            elif [ "$left_meeting_count" -eq 1 ]; then
                  meeting_status="Not in meeting"
            # We may get an event regarding a teams call, but it isn't regarding
            # either a call being started or ended, so, we will use the last
            # state that was recorded.
            else
                  previous_state=$(grep "previous_state:" "$previous_state_file" | cut -d ' ' -f 2,3,4)
                  meeting_status="$previous_state"
            fi
      # User might be in a meeting longer than 30 minutes.
      # In that case, powerd logs may not return any related
      # messages and we need to use the last meeting status that was
      # recorded.
      else
            previous_state=$(grep "previous_state:" "$previous_state_file" | cut -d ' ' -f 2,3,4)
            meeting_status="$previous_state"
      fi
# Handle Old MS Teams where state was written to its log file
else
      fetched_log=$(grep "eventpdclevel: 2, name: desktop_call_state_change_send" ~/Library/Application\ Support/Microsoft/Teams/logs.txt | tail -1)
      if [ -n "$fetched_log" ]; then
            in_meeting_count=$(printf %s "$fetched_log" | grep -Fo "isOngoing: true" | wc -l)
            if [ "$in_meeting_count" -eq 1 ]; then
                  meeting_status="In meeting"
            else
                  meeting_status="Not in meeting"
            fi
      else
            meeting_status="Unknown"
      fi
fi

sensor_state=$(cat <<EOF
{
  "state": "$meeting_status"
}
EOF
)

previous_state=$(grep "previous_state:" "$previous_state_file")
# Only send the state if the state has changed
if [ "$previous_state" != "previous_state: $meeting_status" ]; then
      # Replace last state with new state
      echo "previous_state: $meeting_status" > $previous_state_file
      curl -s -X POST -H "content-type: application/json" --data-raw "$sensor_state" $webhook_url
fi
