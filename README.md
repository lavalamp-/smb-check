# smb-check
A simple bash script that uses smbclient to test access to Windows file shares in automated fashion.

To use the script, create a file that has each IP address to scan on its own line. Place the path for this IP address file in smb-check.sh for the $FILE variable. If you would like to perform authenticated scanning (default is anonymous scanning) then create an authentication file and place the file path in smb-check.sh for the $AUTH_FILE variable.

For reference, an SMB authentication file looks like the following:

> username = <USER>
> password = <PASSWORD>
> domain   = <DOMAIN>

Lastly, the output of the script will be written to the file specified by $OUT_FILE in smb-check.sh.

FYI - there are certain NT_STATUS responses that are currently not accounted for (they pop up fairly rarely in my experience). Any output contained in $OUT_FILE which contains TWO columns instead of THREE can likely be thrown away as erroneous.

Questions? Comments? Bugs? Please let me know via the issues GitHub feature!
