# Aqara Cube Driver for Tasmota (Action Mode Only)

## Overview

This Berry script driver for Tasmota decodes messages from the Aqara Cube T1 Pro (model `lumi.remote.cagl02`) via Zigbee, operating **exclusively in Action Mode**. It converts cube events into a JSON format and publishes them via MQTT with the `AqaraCube` prefix, enabling integration with Tasmota rules or external automation systems. Support for Scene Mode has been intentionally removed to focus on active control actions.

Source: https://github.com/kirovilya/ioBroker.zigbee

## Features

- Automatically detects the Aqara Cube T1 Pro by its Zigbee model (`lumi.remote.cagl02`).
- Processes two event types:
  - **`MultiInValue`**: Shaking, flipping, tapping, and sliding events.
  - **`AnalogValue`**: Cube rotations with direction detection (clockwise or counterclockwise).
- Operates solely in Action Mode for simplicity and reliability.
- Publishes events to MQTT for use in automation.

### Supported Actions

- `shake` (MultiInValue=0)
- `wakeup` (MultiInValue=2)
- `hold` (MultiInValue=4)
- `tap` (MultiInValue≥512, with side indication)
- `slide` (MultiInValue≥256, with side indication)
- `flip180` (MultiInValue≥128, with side indication)
- `flip90` (MultiInValue≥64, with from and to side indications)
- `side_up` (MultiInValue≥1024)
- `rotate_clockwise` (AnalogValue>0, with angle)
- `rotate_counterclockwise` (AnalogValue≤0, with angle)

**Note**: This driver is designed for active control tasks (e.g., toggling devices via gestures) and does not support Scene Mode.

## Installation

1. **Download the Script**:
   - Save the code from `aqara_cube.be` into a file with a `.be` extension.

2. **Upload to Tasmota**:
   - Access the Tasmota web interface.
   - Navigate to **Tools → Manage File System → Upload**.
   - Upload the `aqara_cube.be` file.
  
3. **Startup**:
   - To load the driver on startup select Create and edit new file named `autoexec.be` with a line `load("aqara_cube.be")`.
   - Alternatively you can rename `aqara_cube.be` to `autoexec.be`

4. **Prerequisites**:
   - Ensure your Tasmota device supports Zigbee (e.g., Tasmota-Zigbee firmware).
   - Pair your Aqara Cube T1 Pro with the Zigbee coordinator.

5. **Restart Tasmota**:
   - Run `Restart 1` in the console or restart via the web interface.

## Usage

### Commands

- **`CubeFind`**  
  Manually triggers a search for the Aqara Cube if it wasn’t detected on startup. Use this if the cube was added after the script started.

### Example Tasmota Rules

Create rules to control devices based on cube events:

```tasmota
Rule1
  ON AqaraCube#action=shake DO Power1 TOGGLE ENDON
  ON AqaraCube#action=flip90 DO Dimmer +10 ENDON
  ON AqaraCube#action=rotate_clockwise DO Dimmer +5 ENDON
  ON AqaraCube#action=rotate_counterclockwise DO Dimmer -5 ENDON
  ON AqaraCube#side_up=1 DO Backlog Power1 ON; Power2 OFF ENDON
```

Enable the rule:

```
Rule1 1
```

## Published Message Format

Messages are published to the MQTT topic `tele/tasmota_<DEVICE_ID>/RESULT` with the `AqaraCube` prefix. Examples:
Shaking: `{"AqaraCube":{"action":"shake"}}`

90° Flip: `{"AqaraCube":{"action":"flip90","action_from_side":1,"action_to_side":2,"side":2}}`

Clockwise Rotation: `{"AqaraCube":{"action":"rotate_clockwise","angle":39.42}}`

## Requirements

Tasmota Firmware: Must include Zigbee support (e.g., Tasmota-Zigbee).

Hardware: Aqara Cube T1 Pro paired with the Zigbee coordinator.

## Troubleshooting

If the driver isn’t working:

1. **Check Zigbee Devices:**
Run `ZbStatus` in the Tasmota console to verify the cube is listed.

2. **Verify Messages:**
Ensure `ZbReceived` messages appear in the `tele/tasmota_<DEVICE_ID>/SENSOR` topic.

3. **Restart Search:**
Use the `CubeFind` command to re-detect the cube.

## Code

The driver is written in Berry and located in `aqara_cube.be`. It uses the following imports:
`zigbee` for Zigbee device interaction.

`json` for message formatting.

`string` for address formatting.

## Key Functions

`init()`: Initializes the driver and starts device detection.

`find_device()`: Searches for the Aqara Cube by model.

`handle_zb_received(msg)`: Processes incoming ZbReceived messages and publishes events.

## License

This project is open-source and available under the MIT License (LICENSE). Feel free to modify and distribute as needed.

## Contributions

Contributions are welcome! Submit issues or pull requests to enhance functionality or fix bugs.

