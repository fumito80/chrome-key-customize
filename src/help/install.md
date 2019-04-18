## Shortcutware installation steps

> This extension run on the API called [Native Messaging](https://developer.chrome.com/extensions/nativeMessaging).
> It exchange messages with **Windows native executable**.  
> So, you need to install the executable files at first.  

##### Step 1

Click on the link [scwinst32.exe](scwinst32.exe) and save it.

##### Step 2

Run the saved file to start the installation.

##### Step 3

The installation is complete with a message *"Shortcutware setup succeeded."* in a command prompt.

<pre>
If the message is "Shortcutware setup error! Files are in use.", the installation is already completed and this extension is running.
</pre>

### Installation summary

The following files and registry will be installed.

##### Files:

1. %USERPROFILE%\AppData\Local\Shortcutware\Flexkbd.exe
2. %USERPROFILE%\AppData\Local\Shortcutware\Flexkbd.dll
3. %USERPROFILE%\AppData\Local\Shortcutware\manifest.json

##### Windows Registry:

HKEY\_CURRENT\_USER\Software\Google\Chrome\NativeMessagingHosts\com.scware.nmhost

### Uninstallation steps

<!-- Please remove the installation files and registry manually. -->
##### Step 1

Click on the link [scwremove.exe](scwremove.exe) and save it.

##### Step 2

Run the saved file to start the uninstallation. It removes all the installation files and registry key.

<br>
<br>
