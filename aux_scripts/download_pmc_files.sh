#! /usr/bin/env bash
mkdir -p ./downloaded
./download_from_ftp.py --host "ftp.ncbi.nlm.nih.gov" --user "" --pass "" --remote "/pub/pmc/oa_bulk/oa_comm/xml" --local "./downloaded" --regex "*.tar.gz" --dry > files_to_download
./download_from_ftp.py --host "ftp.ncbi.nlm.nih.gov" --user "" --pass "" --remote "/pub/pmc/oa_bulk/oa_noncomm/xml" --local "./downloaded" --regex "*.tar.gz" --dry >> files_to_download
./download_from_ftp.py --host "ftp.ncbi.nlm.nih.gov" --user "" --pass "" --remote "/pub/pmc/oa_bulk/oa_other/xml" --local "./downloaded" --regex "*.tar.gz" --dry >> files_to_download

./descargar files_to_download