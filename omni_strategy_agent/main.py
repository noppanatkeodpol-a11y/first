import os
import time
from pathlib import Path

# --- Configuration ---
# IMPORTANT: You must update this path to your MetaTrader 5 terminal's common data folder.
# You can find it in MT5 via File -> Open Data Folder -> (Go up one level) -> Common -> Files.
# Example for Windows: C:/Users/YourUser/AppData/Roaming/MetaQuotes/Terminal/Common/Files
# Example for Linux (with Wine): /home/user/.wine/drive_c/users/user/AppData/Roaming/MetaQuotes/Terminal/Common/Files
#
# For this PoC, we will assume the files are in the 'shared_data' directory of the project.
# The MQL5 EA should be configured to write to this same directory.
# In a real setup, you'd use the MT5 Common/Files path.
SHARED_DATA_PATH = Path(__file__).parent / "shared_data"

# --- Ensure the shared directory exists ---
os.makedirs(SHARED_DATA_PATH, exist_ok=True)

MT5_TO_PYTHON_FILE = SHARED_DATA_PATH / "mt5_to_python.txt"
PYTHON_TO_MT5_FILE = SHARED_DATA_PATH / "python_to_mt5.txt"

def main():
    """
    Main function to run the Python side of the communication bridge.
    """
    print("--- Omni-Strategy AI Core ---")
    print(f"Monitoring for data in: {SHARED_DATA_PATH}")
    print("Press Ctrl+C to stop.")

    last_read_time = None

    try:
        while True:
            # --- Python to MQL5 Communication (Write Command) ---
            # For this PoC, we'll just write a simple "PONG" message periodically.
            try:
                with open(PYTHON_TO_MT5_FILE, "w", encoding="utf-8") as f:
                    command = f"ALIVE;{time.time()}"
                    f.write(command)
            except IOError as e:
                print(f"Error writing to {PYTHON_TO_MT5_FILE}: {e}")


            # --- MQL5 to Python Communication (Read Data) ---
            if not MT5_TO_PYTHON_FILE.exists():
                print(f"Waiting for {MT5_TO_PYTHON_FILE} to be created by the MQL5 EA...", end="\r")
                time.sleep(1)
                continue

            try:
                # Check modification time to see if the file has been updated
                current_mod_time = os.path.getmtime(MT5_TO_PYTHON_FILE)

                if current_mod_time != last_read_time:
                    with open(MT5_TO_PYTHON_FILE, "r", encoding="utf-8") as f:
                        content = f.read().strip()
                        if content:
                            print(f"Received data from MQL5: [{content}]")
                            last_read_time = current_mod_time
                        else:
                            print("MQL5 data file is empty.", end="\r")
                else:
                    print("No new data from MQL5.", end="\r")

            except FileNotFoundError:
                # This can happen in a race condition, it's safe to ignore and retry.
                print(f"Waiting for {MT5_TO_PYTHON_FILE}...", end="\r")
            except IOError as e:
                print(f"Error reading {MT5_TO_PYTHON_FILE}: {e}")

            # Wait for a moment before the next check
            time.sleep(2)

    except KeyboardInterrupt:
        print("\nShutting down AI Core.")

if __name__ == "__main__":
    main()