#! /bin/sh

#####################################################################################
#Script Name	:ms-teams-status-local.sh
#Description	:Read your Microsoft Teams meeting status and send it to Home Assistant
#Author       :Robert Drinovac
#GitHub       :https://www.github.com/RobertD502/TeamsStatusMacOS
#License      :MIT
#version      :0.1
#####################################################################################

token="YOUR_LONG_LIVED_TOKEN" # Make sure your token is inside of quotation marks
local_url="http://HOME_ASSISTANT_IP:8123" # Make sure your url is inside of quotation marks
full_url="$local_url/api/states/input_text.microsoft_teams_status"
previous_state_file=~/Documents/Teams_Status/previous_state.txt
fetched_log=$(grep "eventpdclevel: 2, name: desktop_call_state_change_send" ~/Library/Application\ Support/Microsoft/Teams/logs.txt | tail -1)

# Determine the meeting status based on the most recent status in MS Teams log
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

# Create the JSON that will be sent to Home Assistant
sensor_state=$(cat <<EOF
{
  "state": "$meeting_status",
  "attributes": {
    "friendly_name": "Microsoft Teams Status"
  }
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
      curl -s -X POST -H "authorization: Bearer $token" -H "content-type: application/json" --data-raw "$sensor_state" $full_url
fi
