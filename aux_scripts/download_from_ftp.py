#! /usr/bin/env python
import argparse, os
import fnmatch
import ftplib
import warnings
import sys

############################################################################################
## OPTPARSE
############################################################################################

parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-s", "--host", dest="host", default= None,
                    help="FTP host the user is going to connect")

parser.add_argument("-u", "--user", dest="user", default= "",
                    help="FTP host usernarme (dont use it or leave blank if user is not required)")

parser.add_argument("-p", "--pass", dest="pass", default= "",
                    help="FTP host password (dont use it or leave blank if user is not required)")

parser.add_argument("-r", "--remote", dest="remote", default= None,
                    help="Remote folder where all files inside it (in a recursive way) will be downloaded")

parser.add_argument("-l", "--local", dest="local", default= "./",
                    help="Local folder where files will be downloaded")

parser.add_argument("-f", "--regex", dest="regex", default= "*",
                    help="Use it if you want to filter certain type of files")

parser.add_argument("-d", "--dry", dest="dry", default= False, action='store_true',
                    help="(Boolean) Use it to returns the urls of each file inside the folder fulfilling the regex (so you can download it then with wget)")

opts = parser.parse_args()
options = vars(opts)

############################################################################################
## MAIN
############################################################################################

FTP_HOST = options["host"]
FTP_USER = options["user"]
FTP_PASS = options["pass"]

if FTP_HOST == None: raise Exception("Please, define a FTP host to connect with --host flag")
if options["remote"] == None: raise Exception("Please, define a folder within the FPT host to download files with --remote flag")

#connect to FTP Server
ftp = ftplib.FTP(FTP_HOST)
ftp.login(FTP_USER, FTP_PASS)
ftp.encoding = "utf-8"

# if you have to change directory on FTP server.
ftp.cwd(options["remote"])

# Get all files
files = ftp.nlst()

# Download files
for file in files:
    if fnmatch.fnmatch(file, options["regex"]):   #To download specific files.
        if options["dry"]:
            print(f"https://{FTP_HOST}{options['remote']}/{file}")
        else:
            local_file_path = os.path.join(options["local"], file)
            if os.path.isfile(local_file_path) and os.path.getsize(local_file_path) > 0:
                warnings.warn(f"WARNING: You already have file {file} in the path {local_file_path} and size is different from 0, so skipping it")
            else:
                print("INFO: Downloading..." + file + " in FTP path: ", options["remote"], "; to local path: ", options["local"])
                try:
                    ftp.retrbinary("RETR " + file ,open(local_file_path, 'wb').write)
                except EOFError:    # To avoid EOF errors.
                    warnings.warn(f"ERROR: A error has ocurred with file : {file}.  Inside FTP folder: {options['remote']}")
                    pass
ftp.close()