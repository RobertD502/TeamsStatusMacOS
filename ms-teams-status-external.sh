#! /bin/sh

#####################################################################################
#Script Name	:ms-teams-status-external.sh
#Description	:Read your Microsoft Teams meeting status and send it to Home Assistant
#Author       :Robert Drinovac
#GitHub       :https://www.github.com/RobertD502/TeamsStatusMacOS
#License      :MIT
#version      :0.1
#####################################################################################

webhook_url="YOUR_WEBHOOK" # Make sure your webhook url is inside quotation marks
previous_state_file=~/Documents/Teams_Status/previous_state.txt
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

sensor_state=$(cat <<EOF
{
  "state": "$meeting_status"
}
EOF
)

# Create a new previous_state.txt file if one isn't present
if [ ! -f "$previous_state_file" ]; then
      echo "previous_state:" >> "$previous_state_file"
fi

previous_state=$(grep "previous_state:" "$previous_state_file")
# Only send the state if the state has changed
if [ "$previous_state" != "previous_state: $meeting_status" ]; then
      # Replace last state with new state
      echo "previous_state: $meeting_status" > "$previous_state_file"
      curl -s -X POST -H "content-type: application/json" --data-raw "$sensor_state" $webhook_url
fi
