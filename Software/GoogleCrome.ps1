# Set the location of the local temporary directory
$LocalTempDir = $env:TEMP

# Set the name of the Chrome installer executable
$ChromeInstaller = "ChromeSetup.exe"

# Download the Chrome installer executable
   (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/spoddar13/azure_imagebuilder/main/Software/Installer/ChromeSetup.exe", "$LocalTempDir\$ChromeInstaller")

# Execute the installer silently
& "$LocalTempDir\$ChromeInstaller" /silent /install