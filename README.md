# Home Assistant Microsoft Teams Status for MacOS
<a href="https://www.buymeacoffee.com/RobertD502" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="50" width="212"></a>
<a href="https://liberapay.com/RobertD502/donate"><img alt="Donate using Liberapay" src="https://liberapay.com/assets/widgets/donate.svg" height="50" width="150"></a>

Although the Home Assistant MacOS companion app allows you to use the state of your camera and microphone to determine if you are in a Teams meeting, this method doesn't work if you are in a meeting with both off. The aim of this project is to send your meeting status (In meeting, Not in meeting) to Home Assistant without relying on the status of your camera or microphone. This is accomplished by reading the Microsoft Teams log and forwarding the status to Home Assistant.
The Microsoft Teams log is automatically checked every 2 seconds and the current state is sent to Home Assistant if it differs from the previous state.

## Important Note
There are two different methods titled `Local` and `External`.

### External
If you are having to connect to a work VPN, you likely don't have access to your local network. If this is the case, use the `External` method.

**Note:** This method requires that your Home Assistant instance is accessible externally and while connected to your employer's VPN.

### Local
If you don't have to connect to your employer's VPN or, in the rare instance, if you are able to access to your local network while connected to your employer's VPN, use the `Local` method.


## Prerequisites
Regardless of which of the two methods you are using, there are few things that will need to be done:

#### Enable Full Disk Access for sh
1. On your Mac, open "System Preferences" and navigate to "Security & Privacy" and select the `Privacy` tab.
2. On the left-hand side select "Full Disk Access"
3. On the right-hand side, ensure that `sh` is present and checked. If not, proceed to step 4.
4. Click on the lock icon in the lower left-hand corner and enter your password.
5. If `sh` already exists on the right-hand side, but isn't checked, check it to give it Full Disk Access. If it is not present, proceed to step 6.
6. Click on the `+` button. Navigate to your hard drive, then the `bin` folder, select `sh`, and click "Open". If you don't see the `bin` folder when clicking on your hard drive, make hidden folders visible with the following key combination: `cmd` + `shift` + `.`
7. Make sure `sh` is checked if it isn't already after adding it.

![image](https://github.com/RobertD502/TeamsStatusMacOS/assets/52541649/04337bad-1139-4e46-bb11-9aa829e22e76)


#### Create the Teams_Status Directory
1. In your `Documents` folder, create a new folder titled `Teams_Status`

#### Create Input Text Helper in Home Assistant
1. In Home Assistant, navigate to the `Integrations` page.
2. At the top of the page, click on `Helpers`.
3. In the lower right-hand corner, click on `+ CREATE HELPER`.
4. Select `Text` as your helper.
5. Name the helper `Microsoft Teams Status`. *It is important to name the entity exactly this as the scripts rely on a specific entity_id.

## Installation

Download the files from this repository. Depending on which method you are using, follow the corresponding guide below.

<details>
  <summary> <b>Local Method</b> (<i>click to expand</i>)</summary>
  <!---->

### Move the script file
1. Place the file titled `ms-teams-status-local.sh` into the `Teams_Status` folder that you previously created in your `Documents` folder.
2. Make the script executable:
- On your Mac, open a terminal window and execute the following command:
```shell
chmod +x ~/Documents/Teams_Status/ms-teams-status-local.sh
```
3. Remove the quarantine attribute automatically added to the downloaded script:
```shell
xattr -d com.apple.quarantine ~/Documents/Teams_Status/ms-teams-status-local.sh
```
### Move the plist file
1. Place the file titled `com.homeassistant.MSTeamsStatusSender-Local.plist` into `/Users/yourusername/Library/LaunchAgents`

Note: The `Library` folder is a hidden folder. In order to see it, while inside the folder corresponding to your Mac username, press `cmd` + `shift` + `.`

### Create a Long-Lived Token in Home Assistant
1. In Home Assistant, click on your Profile (located in the lower left-hand corner).
2. Scroll down to the section titled `Long-Lived Access Tokens`.
3. Select `CREATE TOKEN`.
4. Give the token a name and click on `Ok`.
5. You will be presented with a long access token. Be sure to save it in a location as you will need it in the steps that follow.

### Edit the script file
1. Open the `ms-teams-status-local.sh` file (located in your Teams_Status folder) in an editor of your choosing.
2. Place your token inside of the `token` variable
3. Place your local Home Assistant URL inside the `local_url` variable, e.g., `"http://192.168.1.42:8123"`
4. Save the changes.

### Load the plist file
On your Mac, open a terminal window and execute the following command:
```shell
launchctl load -w ~/Library/LaunchAgents/com.homeassistant.MSTeamsStatusSender-Local.plist
```

That's it! Whenever you are logged in on your Mac, the script will run every 2 seconds and update the input_text.microsoft_teams_status entity if the current meeting state from the Teams log differs from the previous state.

</details>

<details>
  <summary> <b>External Method</b> (<i>click to expand</i>)</summary>
  <!---->

### Move the script file
1. Place the file titled `ms-teams-status-external.sh` into the `Teams_Status` folder that you previously created in your `Documents` folder.
2. Make the script executable:
- On your Mac, open a terminal window and execute the following command:
```shell
chmod +x ~/Documents/Teams_Status/ms-teams-status-external.sh
```
3. Remove the quarantine attribute automatically added to the downloaded script:
```shell
xattr -d com.apple.quarantine ~/Documents/Teams_Status/ms-teams-status-external.sh
```
### Move the plist file
1. Place the file titled `com.homeassistant.MSTeamsStatusSender-External.plist` into `/Users/yourusername/Library/LaunchAgents`

Note: The `Library` folder is a hidden folder. In order to see it, while inside the folder corresponding to your Mac username, press `cmd` + `shift` + `.`

### Create a Webhook in Home Assistant
1. Go to the `Automations` section of Home Assistant.
2. Create a new automation.
3. For the `Trigger` select `Webhook` and give it an ID.
4. Click on the gear icon next to the ID field and make sure ONLY the box next to `POST` is checked.
5. Add a new action and select `Call service`.
6. Search for and select the `input_text.set_value` service.
7. Select the `input_text.microsoft_teams_status` entity as the target.
8. Paste the following into the Value field: `"{{trigger.json.state}}"`
9. Save the Automation.
10. If you are a NabuCasa user, you will need to enable the webhook and get the webhook URL by navigating to the `Home Assistant Cloud` menu located in the settings.

For those that prefer YAML, this is the full YAML for the automation above:
```yaml
- id: '1686539374529'
  alias: Microsoft Teams Status
  description: ''
  trigger:
  - platform: webhook
    allowed_methods:
    - POST
    local_only: false
    webhook_id: Microsoft_Teams_Status
  condition: []
  action:
  - service: input_text.set_value
    data:
      value: '{{trigger.json.state}}'
    target:
      entity_id: input_text.microsoft_teams_status
  mode: single
```

### Edit the script file
1. Open the `ms-teams-status-external.sh` file (located in your Teams_Status folder) in an editor of your choosing.
2. Place your webhook url inside the `webhook_url` variable
3. Save the changes.

### Load the plist file
On your Mac, open a terminal window and execute the following command:
```shell
launchctl load -w ~/Library/LaunchAgents/com.homeassistant.MSTeamsStatusSender-External.plist
```

That's it! Whenever you are logged in on your Mac, the script will run every 2 seconds and update the input_text.microsoft_teams_status entity if the current meeting state from the Teams log differs from the previous state.

</details>

## Stopping the script

If you no longer want the script to run on your Mac, simply open up a Terminal window and execute the following command (which one depends on your original installation method):

```shell
launchctl unload -w ~/Library/LaunchAgents/com.homeassistant.MSTeamsStatusSender-Local.plist
```

or

```shell
launchctl unload -w ~/Library/LaunchAgents/com.homeassistant.MSTeamsStatusSender-External.plist
```
