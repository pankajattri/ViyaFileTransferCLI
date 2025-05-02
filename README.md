## SAS Viya File Transfer CLI

The viya-file-UD-er is a Command-Line Interface (CLI) application written in Go, designed to upload and download files between a local system and SAS Viya, supporting both SAS Content (Viya’s internal folder structure) and Shared Drive (physical file system). The application can be run interactively or as batch using parameters. Important functionalities are noted below:
1. The application is a single binary. It contains all dependencies and so it can be run without requiring a runtime environment. In other words, all you need is your command prompt/terminal to run the application.
2. Upload or Download one or more file from local or shared drive to SAS Content or Shared Drive in SAS Viya.
3. When uploading file(s) users can choose to upload *.zip, *.tar, and *.tar.gz files and upload them as is OR they can choose to unzip and upload.
4. Similarly, when downloading files users can download files as is, or they can choose to zip all files and download a single *.zip file.

## Setting up the application
1. Download the "CopyFilesFromSASContentToSharedDrive_viceversa.sas" file. Create a new SAS job using this code. Refer to this [link](https://go.documentation.sas.com/doc/en/pgmsascdc/v_062/jobexecug/n055josnxfatfwn1pyr7p1ah7225.htm) here on how to create Jobs. Once created copy the Job ID. When the applicaiton is run the first time specify this job ID for "SAS Job ID" prompt.
2. Download the appropriate binary. viya-file-UD-er for Windows, viya-file-UD-er-linux for Linux and viya-file-UD-er-mac for Mac OS.
3. Navigate to the directory (from command prompt or terminal) where the binary is placed.
4. Run the file using these commands: .\viya-file-UD-er. More details in the section "Running the Applicaiton" below.
5. The first time the file is run user will be asked to provide SAS Viya URL, SAS Job ID, client ID and client Secret. On subsequent upload and download actions user will be asked to provide username, password, and SSL certificate path (if needed by the Viya instance). An option to run in an insecure/non HTTPs way is also provided for testing purposes.
6. There are two main operations that can be performed using the binary: upload and download.
7. The file can be run interactively by accessing 'upload' or 'download' functions and providing text for interactive prompts. Alternatively, values can be provided by using appropriate flags to run the applicaiton via command-line. The flags can be accessed by using --help or -h. E.g., \.viya-file-UD-er.exe upload --help
   
## Authenticating the application
Authenticates with SAS Viya using OAuth (client ID, secret, username, password). Refer to this [article](https://communities.sas.com/t5/SAS-Communities-Library/SAS-Viya-Authenticating-as-a-Custom-Application/ta-p/887079) for helpful details on how to authenticate a custom application.
Stores credentials in ~/.viya/config.json for reuse.

## Running the Application
**Run Modes**
- Interactive Mode: Prompts users for inputs (e.g., folder paths, file names, SAS Content or Shared Drive, zip options).
<pre><code>
.\viya-file-UD-er.exe upload
.\viya-file-UD-er.exe download</code></pre>

The video below shows how the utility can be run to upload files in interactive mode (in Windows). Similar actions can be perfomed on Linux/Mac OS by usign the respective utility binary.

https://github.com/user-attachments/assets/12568d80-7cbb-4fbd-b350-9e5bc743cb7d

The video below shows how the utility can be run to download files in interactive mode (in Windows). Similar actions can be perfomed on Linux/Mac OS by usign the respective utility binary.

https://github.com/user-attachments/assets/8f6ad506-8bac-4dd5-9d00-316b3b003279

- Command-Line Mode: Specifies all parameters via flags for automatin and scripting.
<pre><code>
  .\viya-file-UD-er.exe upload --local-folder "C:\Demo\File Transfer CLI\FilesToUpload" --remote-folder "/nfsshare/sashls2/data/0. CLI File Upload" --files "rlae.sas,lab test types.xlsx,OtherFiles.tar" --destination drive --unzip
  .\viya-file-UD-er.exe download --remote-folder "/nfsshare/sashls2/data/0. CLI File Download" --local-path "C:\Demo\File Transfer CLI\DownloadedFiles" --files "rlae.sas,lab test types.xlsx" --zip
</code></pre>


