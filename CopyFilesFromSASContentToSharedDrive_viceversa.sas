********************************************************;
* Name: Copy files from SAS Content to Shared drive and ; 
*       vice-verse		                                ;
* Description: Copies files from SAS Content Drive to	;
*				Shared drive folder path.				;
*														;
* Arguments:                                            ;
* source_folder: Folder name in SAS Content				;
* dest_folder: Folder name in Shared drive				;
* file_list: List of files to be copied from the source ;
* folder to the destination folder.						;
********************************************************;

%global source_folder dest_folder file_list;

%put Source Folder is: &source_folder;
%put Destination folder is: &dest_folder;
%put Files to copy are: &file_list;

%macro file_copy_SASC_To_Drive(source_folder, dest_folder, file_list);
/* Macro to copy multiple files from source folder in SAS Content to destination folder in Shared Drive */
%local rc msg file_name i file_ext;

/* Enable strict error checking */
options errorcheck=strict;

/* Input parameter validation */
%if %length(&source_folder) = 0 %then %do;
   %put ERROR: Source folder path is missing.;
   %goto exit_macro;
%end;

%if %length(&dest_folder) = 0 %then %do;
   %put ERROR: Destination folder path is missing.;
   %goto exit_macro;
%end;

%if %length(&file_list) = 0 %then %do;
   %put ERROR: File list is missing.;
   %goto exit_macro;
%end;

/* Loop through each file in the file list */
%let i = 1;
%let file_name = %scan(&file_list, &i, %str(,));
%do %while(%length(&file_name) > 0);
   /* Construct source and destination file paths */
   %let source_file = &source_folder/&file_name;
   %let dest_file = &dest_folder/&file_name;

   /* Get file extension */
   %let file_ext = %lowcase(%scan(&file_name, -1, .));

   /* Define filenames with error handling */
   filename srcfile filesrvc folderpath="&source_folder" filename="&file_name" recfm=n lrecl=32767;
   %if %sysfunc(fexist(srcfile)) = 0 %then %do;
      %put ERROR: Source file &source_file does not exist or is inaccessible.;
      /* Set SYSCC to indicate error */
      %let SYSCC = 8;
      filename srcfile clear;
      %goto next_file;
   %end;

   filename destfile "&dest_file" recfm=n lrecl=32767;
   %if %sysfunc(filename(destfile, &dest_file)) ne 0 %then %do;
      %put ERROR: Failed to assign destination filename &dest_file.;
      /* Set SYSCC to indicate error */
      %let SYSCC = 8;
      filename srcfile clear;
      filename destfile clear;
      %goto next_file;
   %end;

   /* Log file information */
   %put NOTE: Attempting to copy &source_file to &dest_file;
   %put NOTE: Source file exists: %sysfunc(fexist(srcfile));

   /* Handle SAS datasets (.sas7bdat) differently */
   /* This WILL NOT WORK when source is SAS Content. Libref will not be valid. Using dummy file ext for now to fall back on fcopy. */
   %if &file_ext = DUMMY %then %do;
      /* Use PROC COPY for SAS datasets */
      libname src_lib "&source_folder";
      libname dest_lib "&dest_folder";
      proc copy in=src_lib out=dest_lib;
         select %scan(&file_name, 1, .);
      run;
      /* Check SYSCC after PROC COPY */
      %if &SYSCC > 0 %then %do;
         %put ERROR: PROC COPY failed for &file_name. SYSCC=&SYSCC;
         libname src_lib clear;
         libname dest_lib clear;
         /* Force job failure */
         endsas 8;
      %end;
      libname src_lib clear;
      libname dest_lib clear;
      %put NOTE: Successfully copied SAS dataset &file_name using PROC COPY.;
   %end;
   %else %do;
      /* Perform file copy operation for non-SAS datasets */
      data _null_;
         rc = fcopy("srcfile", "destfile");
         msg = sysmsg();
         call symputx('rc', rc);
         call symputx('msg', msg);
         /* If fcopy fails, set SYSCC and force failure */
         if rc ne 0 then do;
            call symputx('SYSCC', 8); /* Set SYSCC to indicate error */
            put "ERROR: FCOPY failed with RC=" rc;
            put "ERROR: " msg;
         end;
      run;

      /* Check fcopy result and force failure if needed */
      %if &rc ne 0 %then %do;
         %put ERROR: File copy failed for &file_name. RC=&rc;
         %put ERROR: &msg;
         /* Force job failure */
         endsas 8;
      %end;
      %else %do;
         %put NOTE: File successfully copied from &source_file to &dest_file.;
      %end;
   %end;

   /* Clean up filename references */
   filename srcfile clear;
   filename destfile clear;

   %next_file:
   %let i = %eval(&i + 1);
   %let file_name = %scan(&file_list, &i, %str(,));
%end;

/* Final SYSCC check before exiting */
%if &SYSCC > 0 %then %do;
   %put ERROR: Job encountered errors (SYSCC=&SYSCC). Terminating.;
   endsas 8;
%end;

%exit_macro:
%mend file_copy_SASC_To_Drive;


%macro file_copy_Drive_To_SASC(source_folder, dest_folder, file_list);
/* Macro to copy files from shared drive to SAS Content */
%local i file_name rc msg file_list_new did nfiles fname;

/* Enable strict error checking */
options errorcheck=strict;

/* Input parameter validation */
%if %length(&source_folder) = 0 %then %do;
   %put ERROR: Source folder path is missing.;
   %let SYSCC = 8;
   %goto exit_macro;
%end;

%if %length(&dest_folder) = 0 %then %do;
   %put ERROR: Destination folder path is missing.;
   %let SYSCC = 8;
   %goto exit_macro;
%end;

/* Check for empty file_list and generate list from source_folder if needed */
%if %length(&file_list) = 0 %then %do;
   /* Assign fileref to source_folder */
   filename mydir "&source_folder";
   %if %sysfunc(filename(mydir, &source_folder)) ne 0 %then %do;
      %put ERROR: Failed to assign fileref for source folder &source_folder.;
      %let SYSCC = 8;
      filename mydir clear;
      %goto exit_macro;
   %end;

   /* Open the directory */
   %let did = %sysfunc(dopen(mydir));
   %if &did = 0 %then %do;
      %put ERROR: Unable to open source folder &source_folder.;
      %let SYSCC = 8;
      filename mydir clear;
      %goto exit_macro;
   %end;

   /* Get number of files */
   %let nfiles = %sysfunc(dnum(&did));
   %put NOTE: Number of entries found in &source_folder: &nfiles;
   %if &nfiles = 0 %then %do;
      %put ERROR: No files found in source folder &source_folder.;
      %let SYSCC = 8;
      %let rc = %sysfunc(dclose(&did));
      filename mydir clear;
      %goto exit_macro;
   %end;

   /* Build comma-separated file list */
   %let file_list_new = ;
   %do i = 1 %to &nfiles;
      %let fname = %sysfunc(dread(&did, &i));
      %put NOTE: Processing file: &fname;
      %if %length(&file_list_new) = 0 %then %do;
         %let file_list_new = &fname;
      %end;
      %else %do;
         %let file_list_new = &file_list_new,&fname;
      %end;
   %end;

   /* Close the directory */
   %let rc = %sysfunc(dclose(&did));
   %put NOTE: Directory closed with rc=&rc;

   /* Clean up fileref */
   filename mydir clear;

   /* Check if any files were found */
   %if %length(&file_list_new) = 0 %then %do;
      %put ERROR: No valid files found in source folder &source_folder.;
      %let SYSCC = 8;
      %goto exit_macro;
   %end;

   /* Assign new file list */
   %let file_list = %quote(&file_list_new);
   %put NOTE: Extracted file list from &source_folder: &file_list;
%end;

/* Validate file_list after extraction */
%if %length(&file_list) = 0 %then %do;
   %put ERROR: File list is empty after processing.;
   %let SYSCC = 8;
   %goto exit_macro;
%end;

/* Loop through each file in the file list */
%let i = 1;
%let file_name = %scan(&file_list, &i, %str(,));
%do %while(%length(&file_name) > 0);
   %put NOTE: Scanning file_name: &file_name;
   /* Construct source and destination file paths */
   %let source_file = &source_folder/&file_name;
   %let dest_file = &dest_folder/&file_name;

   /* Define filenames */
   filename srcfile "&source_file" recfm=n lrecl=32767;
   %if %sysfunc(fexist(srcfile)) = 0 %then %do;
      %put ERROR: Source file &source_file does not exist or is inaccessible.;
      %let SYSCC = 8;
      filename srcfile clear;
      %goto next_file;
   %end;

   filename destfile filesrvc folderpath="&dest_folder" filename="&file_name" recfm=n lrecl=32767;

   /* Log file information */
   %put NOTE: Attempting to copy &source_file to &dest_file;

   /* Perform file copy */
   data _null_;
      rc = fcopy("srcfile", "destfile");
      msg = sysmsg();
      call symputx('rc', rc);
      call symputx('msg', msg);
      if rc ne 0 then do;
         put "ERROR: FCOPY failed for &file_name with rc=" rc;
         put "ERROR: " msg;
         call symputx('SYSCC', 8);
      end;
   run;

   /* Check fcopy result */
   %if &rc ne 0 %then %do;
      %put ERROR: File copy failed for &file_name. RC=&rc;
      %put ERROR: &msg;
      %if %index(&msg, %str(folder)) or %index(&msg, %str(path)) %then %do;
         %put WARNING: Failure may be due to invalid or inaccessible destination folder &dest_folder.;
      %end;
      filename srcfile clear;
      filename destfile clear;
      %goto next_file;
   %end;
   %else %do;
      %put NOTE: File successfully copied from &source_file to &dest_file.;
   %end;

   /* Clean up filename references */
   filename srcfile clear;
   filename destfile clear;

   %next_file:
   %let i = %eval(&i + 1);
   %let file_name = %scan(&file_list, &i, %str(,));
%end;

/* Final SYSCC check */
%if &SYSCC > 0 %then %do;
   %put ERROR: Job encountered errors (SYSCC=&SYSCC).;
   %goto exit_macro;
%end;
%else %do;
   %put NOTE: All files in file_list successfully copied.;
%end;

%exit_macro:
%mend file_copy_Drive_To_SASC;


%macro runCopy(operation_type, source_folder, dest_folder, file_list);
/* Macro to run file_copy_SASC_To_Drive or file_copy_Drive_To_SASC based on operation_type */
%local syscc_prev;

/* Store initial SYSCC */
%let syscc_prev = &SYSCC;

/* Input parameter validation */
%if %length(&operation_type) = 0 %then %do;
   %put ERROR: Operation type is missing.;
   %let SYSCC = 8;
   %goto exit_macro;
%end;

%if %length(&source_folder) = 0 %then %do;
   %put ERROR: Source folder path is missing.;
   %let SYSCC = 8;
   %goto exit_macro;
%end;

%if %length(&dest_folder) = 0 %then %do;
   %put ERROR: Destination folder path is missing.;
   %let SYSCC = 8;
   %goto exit_macro;
%end;

%if %length(&file_list) = 0 and %upcase(&operation_type) = UPLOAD %then %do;
   %put ERROR: File list is missing.;
   %let SYSCC = 8;
   %goto exit_macro;
%end;

/* Run appropriate macro based on operation_type */
%if %upcase(&operation_type) = UPLOAD %then %do;
   %file_copy_SASC_To_Drive(&source_folder, &dest_folder, %quote(&file_list));
%end;
%else %if %upcase(&operation_type) = DOWNLOAD %then %do;
   %file_copy_Drive_To_SASC(&source_folder, &dest_folder, %quote(&file_list));
%end;
%else %do;
   %put ERROR: Invalid operation_type &operation_type. Must be UPLOAD or DOWNLOAD.;
   %let SYSCC = 8;
   %goto exit_macro;
%end;

/* Check SYSCC after macro execution */
%if &SYSCC > 0 %then %do;
   %put ERROR: Copy operation failed with SYSCC=&SYSCC.;
   endsas 8;
%end;

%exit_macro:
/* Restore SYSCC if no errors */
%if &SYSCC = 0 and &syscc_prev ne &SYSCC %then %do;
   %let SYSCC = &syscc_prev;
%end;
%mend runCopy;

%runCopy(operation_type=&operation_type,source_folder=&source_folder,dest_folder=&dest_folder,file_list=%quote(&file_list));
