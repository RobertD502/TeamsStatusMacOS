#! /bin/sh

#####################################################################################
#Script Name	:ms-teams-status-local.sh
#Description	:Read your Microsoft Teams meeting status and send it to Home Assistant
#Author       :Robert Drinovac
#GitHub       :https://www.github.com/RobertD502/TeamsStatusMacOS
#License      :MIT
#version      :0.2
#####################################################################################

teams_version="Old | New" # Set this to EITHER "Old" or "New" depending on the teams version you are using (See GitHub documentation)
token="YOUR_LONG_LIVED_TOKEN" # Make sure your token is inside of quotation marks
local_url="http://HOME_ASSISTANT_IP:8123" # Make sure your url is inside of quotation marks
full_url="$local_url/api/states/input_text.microsoft_teams_status"
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

previous_state=$(grep "previous_state:" "$previous_state_file")
# Only send the state if the state has changed
if [ "$previous_state" != "previous_state: $meeting_status" ]; then
      # Replace last state with new state
      echo "previous_state: $meeting_status" > $previous_state_file
      curl -s -X POST -H "authorization: Bearer $token" -H "content-type: application/json" --data-raw "$sensor_state" $full_url
fi
