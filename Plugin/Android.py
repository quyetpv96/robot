from symtable import Symbol
from robot.api.deco import keyword
from ppadb.client import Client as AdbClient
import subprocess


class Android:
    def __int__(self):
        self._client = None  # adb server
        self._devices = None  # adb devices
        self._device = None  # current device
        self._serial = None  # adb -s option
        self._thread = None


    @keyword('Shell')
    def send_adb_command(sefl, device_id, command):
        try:
            result = subprocess.run(
                ["adb", "-s", device_id, "shell", command],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                print(f"Command executed successfully:\n{result.stdout}")
            else:
                print(f"Error executing command:\n{result.stderr}")
        except Exception as e:
            print(f"An error occurred: {e}")

    @keyword('Connect Adb server')
    def connect_to_device(self, device_id):
        client = AdbClient(host="127.0.0.1", port=5037)
        device = client.device(device_id)
        if device is None:
            print("Unable to connect to the device.")
            return None
        print("Device connected successfully.")
        return device

    @keyword('Disconnect Adb server')
    def send_adb_command(self, device, command):
        try:
            result = device.shell(command)
            print(result)
        except Exception as e:
            print(f"An error occurred while sending the command: {e}")

    @keyword('Touch')
    def adb_tap(self, x, y, serial=None):
        """run `adb input tap` ``x`` ``y``

        argument:
        - ``x`` : x coordinate of touch
        - ``y`` : y coordinate of touch
        - ``serial`` : if serial is None, select the first device in the adb device list then make touch. else select the device named ``serial`` then make touch. it's same '-s' option in adb

        Examples:
        | `Touch` |  900  | 1000 |
        | `Touch` |  900  | 1000 |  R3CR600XL3D |
        """
        if serial is None:
            self._device.input_tap(x, y)
        else:
            self.select_adb_device(serial)
            if self._device is not None:
                self._device.input_tap(x, y)
            else:
                print(serial + ' device connection is none')


if __name__ == "__main__":
    device_id = "emulator-5554"
    android = Android()
    device = android.connect_to_device(device_id)
