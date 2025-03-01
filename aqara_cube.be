import zigbee
import json
import string

# Class for handling messages from Aqara Cube
class AqaraCubeDriver
    var device_addr       # Device address
    
    def init()
        self.device_addr = nil
        tasmota.add_driver(self)
        #print("DEBUG: AqaraCubeDriver initialized in action mode")
        self.find_device()  # Search for device on initialization
        tasmota.add_rule("ZbReceived", / val -> self.handle_zb_received(val))
    end
    
    # Search for Zigbee device by model
    def find_device()
        #print("DEBUG: Starting device discovery")
        for d : zigbee
            var addr_hex = string.format("0x%04X", d.shortaddr)
            #print("DEBUG: Checking device - shortaddr:", addr_hex, "model:", d.model)
            if d.model == 'lumi.remote.cagl02'
                self.device_addr = addr_hex
                #print("DEBUG: Found Aqara Cube device - address:", self.device_addr)
                break
            end
        end
        #if !self.device_addr
        #    print("DEBUG: No Aqara Cube device found")
        #end
    end
    
    # Handle incoming ZbReceived messages
    def handle_zb_received(msg)
        var result = {}
        #print("DEBUG: Received ZbReceived message:", json.dump(msg))
        
        if self.device_addr && msg.contains(self.device_addr)
            #print("DEBUG: Processing ZbReceived for device:", self.device_addr)
            var data = msg[self.device_addr]
            #print("DEBUG: Data received from device:", json.dump(data))
            
            # Process MultiInValue
            if data.contains("MultiInValue")
                var value = data["MultiInValue"]
                #print("DEBUG: Processing MultiInValue:", value)
                if value == 0
                    result['action'] = 'shake'
                elif value == 2
                    result['action'] = 'wakeup'
                elif value == 4
                    result['action'] = 'hold'
                elif value >= 512
                    result['action'] = 'tap'
                    result['side'] = value - 511
                elif value >= 256
                    result['action'] = 'slide'
                    result['side'] = value - 255
                elif value >= 128
                    result['action'] = 'flip180'
                    result['side'] = value - 127
                elif value >= 64
                    result['action'] = 'flip90'
                    result['action_from_side'] = int((value - 64) / 8) + 1
                    result['action_to_side'] = (value % 8) + 1
                    result['side'] = (value % 8) + 1
                elif value >= 1024
                    result['action'] = 'side_up'
                    result['side_up'] = value - 1023
                end
                #print("DEBUG: Action determined from MultiInValue:", result['action'])
            end
            
            # Process AnalogValue with rotation direction detection
            if data.contains("AnalogValue")
                var angle = data["AnalogValue"]
                #print("DEBUG: Processing AnalogValue:", angle)
                if angle > 0
                    result['action'] = 'rotate_clockwise'
                else
                    result['action'] = 'rotate_counterclockwise'
                end
                result['angle'] = angle
                #print("DEBUG: Action determined from AnalogValue:", result['action'], "angle:", angle)
            end
            
            # Publish result (no operation_mode, only action mode)
            if size(result) > 0
                #print("DEBUG: Publishing result:", json.dump(result))
                tasmota.publish_result(json.dump(result), 'AqaraCube')
                return true
            #else
            #    print("DEBUG: No actionable data found in message")
            #end
        #else
        #    print("DEBUG: No device address set or message not for target device:", self.device_addr)
        #end
        return false
    end
end

# Driver initialization
aqara_cube = AqaraCubeDriver()

# Command to manually trigger device search
def cmd_find(cmd, idx, payload)
    #print("DEBUG: Manual device find triggered")
    aqara_cube.find_device()
    return true
end

tasmota.add_cmd('CubeFind', cmd_find)