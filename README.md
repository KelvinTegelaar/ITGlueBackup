# IT-Glue backup tool
See https://www.cyberdrain.com/it-glue-unofficial-backup-script/ for more information.

to make sure that IT-Glue partners get some form of data portability and backups I’ve created the following script. The script connects to the IT-Glue API and creates a HTML and CSV export of all Flexible Assets and Passwords in IT-Glue.

It does not currently backup documents, as those are not exposed by the API. The export always creates 2 files; one HTML file for quick viewing, and a CSV file with all the information included.

*Disclaimer/warning:* The HTML files contain all your documentation, in plain-text format. Store this in a safe location or adapt the script to upload the data to your Azure Key Vault or secondary password management tool instead. Do not store these in a public location.