#####################################################################
#The unofficial Kelvin Tegelaar IT-Glue Backup script. Run this script whenever you want to create a backup of the ITGlue database.
#Creates a file called "password.html" with all passwords in Plain-text. please only store in secure location.
#Creates folders per organisation, and copies flexible assets there as HTML table  &amp; CSV file for data portability.
$APIKEy = "YourITGAPIKey"
$APIEndpoint = "https://api.eu.itglue.com"
$ExportDir = "C:\Hello\ITGBackup"
#####################################################################

if (!(Test-Path $ExportDir)) {
    Write-Host "Creating backup directory" -ForegroundColor Green
    new-item $ExportDir -ItemType Directory 
}

#Header for HTML files, to make it look pretty.
$head = @"
<script>
function myFunction() {
    const filter = document.querySelector('#myInput').value.toUpperCase();
    const trs = document.querySelectorAll('table tr:not(.header)');
    trs.forEach(tr => tr.style.display = [...tr.children].find(td => td.innerHTML.toUpperCase().includes(filter)) ? '' : 'none');
  }</script>
<title>Export File Documentation</title>
<style>
body { background-color:#E5E4E2;
      font-family:Monospace;
      font-size:10pt; }
td, th { border:0px solid black; 
        border-collapse:collapse;
        white-space:pre; }
th { color:white;
    background-color:black; }
table, tr, td, th {
     padding: 2px; 
     margin: 0px;
     white-space:pre; }
tr:nth-child(odd) {background-color: lightgray}
table { width:95%;margin-left:5px; margin-bottom:20px; }
h2 {
font-family:Tahoma;
color:#6D7B8D;
}
.footer 
{ color:green; 
 margin-left:10px; 
 font-family:Tahoma;
 font-size:8pt;
 font-style:italic;
}
#myInput {
  background-image: url('https://www.w3schools.com/css/searchicon.png'); /* Add a search icon to input */
  background-position: 10px 12px; /* Position the search icon */
  background-repeat: no-repeat; /* Do not repeat the icon image */
  width: 50%; /* Full-width */
  font-size: 16px; /* Increase font-size */
  padding: 12px 20px 12px 40px; /* Add some padding */
  border: 1px solid #ddd; /* Add a grey border */
  margin-bottom: 12px; /* Add some space below the input */
}
</style>
"@

#ITGlue Download starts here
If (Get-Module -ListAvailable -Name "ITGlueAPI") { Import-module ITGlueAPI } Else { install-module ITGlueAPI -Force; import-module ITGlueAPI }
#Settings IT-Glue logon information
Add-ITGlueBaseURI -base_uri $APIEndpoint
Add-ITGlueAPIKey $APIKEy
$i = 0
#grabbing all orgs for later use.
do {
    $orgs += (Get-ITGlueOrganizations -page_size 1000 -page_number $i).data
    $i++
    Write-Host "Retrieved $($orgs.count) Organisations" -ForegroundColor Yellow
}while ($orgs.count % 1000 -eq 0 -and $orgs.count -ne 0)
#Grabbing all passwords.
Write-Host "Getting passwords" -ForegroundColor Green
do {
    $i++
    $PasswordList += (Get-ITGluePasswords -page_size 1000 -page_number $i).data
    Write-Host "Retrieved $($PasswordList.count) Passwords" -ForegroundColor Yellow
}while ($PasswordList.count % 1000 -eq 0 -and $PasswordList.count -ne 0)
Write-Host "Processing Passwords. This might take some time." -ForegroundColor Yellow
$Passwords = foreach ($PasswordItem in $passwordlist) {
    (Get-ITGluePasswords -show_password $true -id $PasswordItem.id).data
}
Write-Host "Processed Passwords. Moving on." -ForegroundColor Yellow

Write-Host "Creating backup directory per organisation." -ForegroundColor Green
foreach ($org in $orgs) {
    if (!(Test-Path "$($ExportDir)\$($org.attributes.name)")) { 
        $org.attributes.name = $($org.attributes.name).Replace('\W', " ")
        new-item "$($ExportDir)\$($org.attributes.name)" -ItemType Directory | out-null 
        Write-Host "Creating password file for $($org.attributes.name)" -ForegroundColor Green
        $Passwords.attributes | where-object {$_.'organization-name' -eq $($org.attributes.name) } |select-object 'organization-name', name, username, password, url, created-at, updated-at | convertto-html -head $head -precontent '<h1>Password export</h1><input type="text" id="myInput" onkeyup="myFunction()" placeholder="Search for content.." title="Type a query">' | out-file "$($ExportDir)\$($org.attributes.name)\passwords.html"
    }
}

$i = 0


Write-Host "Getting Flexible Assets" -ForegroundColor Green
$FlexAssetTypes = (Get-ITGlueFlexibleAssetTypes -page_size 1000).data
foreach ($FlexAsset in $FlexAssetTypes) {
    $i = 0
    do {
        $i++
        Write-Host "Getting FlexibleAssets for $($Flexasset.attributes.name)" -ForegroundColor Yellow
        $FlexibleAssets += (Get-ITGlueFlexibleAssets -filter_flexible_asset_type_id $FlexAsset.id -page_size 1000 -page_number $i).data
        Write-Host "Retrieved $($FlexibleAssets.count) Flexible Assets" -ForegroundColor Yellow
    }while ($FlexibleAssets.count % 1000 -eq 0 -and $FlexibleAssets.count -ne 0)
}
 
write-host "Exporting all Password to $($ExportDir)\passwords.html"
$Passwords.attributes | select-object 'organization-name', name, username, password, url, created-at, updated-at | convertto-html -head $head -precontent '<h1>Password export from IT-Glue</h1><input type="text" id="myInput" onkeyup="myFunction()" placeholder="Search for content.." title="Type a query">' | out-file "$($ExportDir)\passwords.html"

foreach ($FlexibleAsset in $FlexibleAssets.attributes) {
    $HTMLTop = @"
<h1> Flexible Asset Information </h1>
<b>organization ID: </b>$($FlexibleAsset."organization-id") <br>
<b>organization Name:</b>$($FlexibleAsset."organization-name")<br>
<b>name:</b>$($FlexibleAsset.name)<br>
<b>created-at </b>$($FlexibleAsset."created-at")<br>
<b>updated-at </b>$($FlexibleAsset."updated-at")<br>
<b>resource url: </b>$($FlexibleAsset."resource-url")<br>
<b>flexible-asset-type-id: </b>$($FlexibleAsset."flexible-asset-type-id")<br>
<b>flexible-asset-type-name: </b>$($FlexibleAsset."flexible-asset-type-name")<br>
"@ 

    $HTMLTables = $FlexibleAsset.traits | convertto-html -Head $head -PreContent "$HTMLTop <br> <h1> Flexible Asset Traits</h1>"

    write-host "Ouputting $outputpath" -ForegroundColor Yellow
    $OutputPath = "$($ExportDir)\$($flexibleasset.'organization-name')"
    $outputfilename = "$($Flexibleasset.'flexible-asset-type-name') - $($Flexibleasset.name)"
    $outputfilename = $outputfilename.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

    write-host "Ouputting $outputpath\$outputfilename" -ForegroundColor Yellow
    $HTMLTables | out-file "$outputpath\$($outputfilename).html" -Force
    $FlexibleAsset.traits | export-csv -path "$outputpath\$($outputfilename).csv" -Force -NoTypeInformation
}