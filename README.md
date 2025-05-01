SAS Viya File Transfer CLI

This Command Line Interface utility allows users to upload and download files from their local directories to SAS Content or Shared drive in SAS Viya. The utility can also be scheduled if needed. Important functionalities are noted below:
1. Upload or Download one or more file from local or shared drive to SAS Content or Shared Drive in SAS Viya.
2. When uploading file(s) users can choose to upload *.zip, *.tar, and *.tar.gz files and upload them as is OR they can choose to unzip and upload.
3. Similarly, when downloading files users can download files as is, or they can choose to zip all files and download a single *.zip file.

The video below shows how the utility can be run to upload files via a command prompt (in Windows). Similar actions can be perfomed on Linux/Mac OS by usign the respective utility binary.

https://github.com/user-attachments/assets/12568d80-7cbb-4fbd-b350-9e5bc743cb7d

The video below shows how the utility can be run to download files via a command prompt (in Windows). Similar actions can be perfomed on Linux/Mac OS by usign the respective utility binary.

https://github.com/user-attachments/assets/8f6ad506-8bac-4dd5-9d00-316b3b003279

Steps to Install:
1. Download the appropriate binary. viya-file-UD-er for Windows, viya-file-UD-er-linux for Linux and viya-file-UD-er-mac for Mac OS.
2. Navigate to the directory (from command prompt or terminal) where the binary is placed.
3. Run the file using these commands: .\viya-file-UD-er.
4. The first time the file is run user will have to provide SAS Viya URL, client ID and client Secret. On subsequent uplaod and download actions user will be asked to provide username, password, and SSL certificate path (if needed by the Viya instance). An option to run in an insecure/non HTTPs way is also provided for testing purposes.
5. There are two main operations that can be performed using the binary: upload and download.
6. The file can be run interactively by accessing 'upload' or 'download' functions and providing prompt values. Alternatively, prompts can be provided by using appropriate flags. The flags can be accessed by using --help or -h. E.g., \.viya-file-UD-er.exe upload --help
