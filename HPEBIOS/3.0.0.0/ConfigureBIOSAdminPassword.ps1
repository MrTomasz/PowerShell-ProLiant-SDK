﻿########################################################
#Configuring BIOS administrator password
###################################################----#

<#
.Synopsis
    This script allows user to sets the BIOS administrator password of HPE Proliant Gen9, Gen10 and Gen10 Plus servers. 

.DESCRIPTION
    This script allows user to set the BIOS administrator password.It sets the admin password first time, means when no previous passowrd is set. 
    After configuring administrator password target server can be restart using RestartServer switch parameter.
	
.EXAMPLE
    ConfigureBIOSAdminPassword.ps1

    This mode of execution of script will prompt for 
    
    -Address:- Accept IP(s) or Hostname(s). In case multiple entries it should be separated by comma(,)
    
    -Credential:- it will prompt for user name and password. In case multiple server IP(s) or Hostname(s) it is recommended to use same user credentials
       
    -AdminPassword:- it will prompt to enter a admin password.
    
.EXAMPLE
    ConfigureBIOSAdminPassword.ps1 -Address "10.20.30.40,10.25.35.45" -Credential $userCrdential -RestartServer

    This mode of script needs following parameters:
    
    -Address:- Use this parameter specify  IP(s) or Hostname(s) of the server(s). In the of case multiple entries it should be separated by comma(,)
    
    -Credential:- Use this parameter to specify user credential.# In case of multiple servers use same credential for all the servers

    -RestartServer:- use this switch parameter to restart the server.
    
    -AdminPassword:- it will prompt to enter a new admin password.

.NOTES
    
    Company : Hewlett Packard Enterprise
    Version : 3.0.0.0
    Date    : 11/04/2020
    
.INPUTS
    Inputs to this script file
    Address
    Credential
    

.OUTPUTS
    None (by default)

.LINK
    http://www.hpe.com/servers/powershell
    https://github.com/HewlettPackard/PowerShell-ProLiant-SDK/tree/master/HPEBIOS
#>



#Command line parameters
Param(
    # IP(s) or Hostname(s).Multiple addresses seperated by comma(,).
    [string[]]$Address,   
    #In case of multiple servers it use same credential for all the servers.
    [PSCredential]$Credential,
    #Specify the admin password to set . Note :- This will set the admin password first time only.
    [string[]]$AdminPassword,
    # When this switch parameter is present target server will restart after configuring BIOS administrator password.
    [Switch]$RestartSever
     )


 #Check for server avaibiality

 function CheckServerAvailability ($ListOfAddress)
 {
    [int]$pingFailureCount = 0
    [array]$PingedServerList = @()
    foreach($serverAddress in $ListOfAddress)
    {
       if(Test-Connection $serverAddress)
       {
         $PingedServerList += $serverAddress
         
       }
       else
       {
         Write-Host ""
         Write-Host "Server $serverAddress is not reachable. Please check network connectivity"
         $pingFailureCount ++
       }
    }

    if($pingFailureCount -eq $ListOfAddress.Count)
    {
        Write-Host ""
        Write-Host "Server(s) are not reachable please check network conectivity"
        exit
    }
    return $PingedServerList
 }




#clear host
Clear-Host

# script execution started
Write-Host "******Script execution started******" -ForegroundColor Green
Write-Host ""
#Decribe what script does to the user

Write-Host "This script demonstrate how to set a new AdminPassword. A new AdminPassword can be set,an existing administrator password can be modified or the administrator password can be cleared/removed or reset."
Write-Host ""

#dont show error in script

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Continue"
#$ErrorActionPreference = "Inquire"
$ErrorActionPreference = "SilentlyContinue"

#check powershell support
#Write-Host "Checking PowerShell version support"
#Write-Host ""
$PowerShellVersion = $PSVersionTable.PSVersion.Major

if($PowerShellVersion -ge "3")
{
    Write-Host "Your powershell version : $($PSVersionTable.PSVersion) is valid to execute this script"
    Write-Host ""
}
else
{
    Write-Host "This script required PowerSehll 3 or above"
    Write-Host "Current installed PowerShell version is $($PSVersionTable.PSVersion)"
    Write-Host "Please Update PowerShell version"
    Write-Host ""
    Write-Host "Exit..."
    Write-Host ""
    exit
}

#Load HPEBIOSCmdlets module
#Write-Host "Checking HPEBIOSCmdlets module"
#Write-Host ""

$InstalledModule = Get-Module
$ModuleNames = $InstalledModule.Name

if(-not($ModuleNames -like "HPEBIOSCmdlets"))
{
    Write-Host "Loading module :  HPEBIOSCmdlets"
    Import-Module HPEBIOSCmdlets
    if(($(Get-Module -Name "HPEBIOSCmdlets")  -eq $null))
    {
        Write-Host ""
        Write-Host "HPEBIOSCmdlets module cannot be loaded. Please fix the problem and try again"
        Write-Host ""
        Write-Host "Exit..."
        exit
    }
}
else
{
    $InstalledBiosModule  =  Get-Module -Name "HPEBIOSCmdlets"
    Write-Host "HPEBIOSCmdlets Module Version : $($InstalledBiosModule.Version) is installed on your machine."
    Write-host ""
}

# check for IP(s) or Hostname(s) Input. if not available prompt for Input

if($Address.Count -eq 0)
{
    $Address = Read-Host "Enter Server address (IP or Hostname). Multiple entries seprated by comma(,)"
}
    
[array]$ListOfAddress = ($Address.Trim().Split(','))

if($ListOfAddress.Count -eq 0)
{
    Write-Host "You have not entered IP(s) or Hostname(s)"
    Write-Host ""
    Write-Host "Exit ..."
    exit
}

if($Credential -eq $null)
{
    $Credential = Get-Credential -Message "Enter username and Password(Use same credential for multiple servers)"
    Write-Host ""
}

#  Ping and test IP(s) or Hostname(s) are reachable or not
$ListOfAddress =  CheckServerAvailability($ListOfAddress)

# create connection object
[array]$ListOfConnection = @()
$connection = $null
[int] $connectionCount = 0
[array]$OldAdminPassword=@()
for($i=0;$i -lt $ListOfAddress.Count; $i++)
{
    Write-Host ""
    Write-Host ("Connecting to server  : {0}" -f $ListOfAddress[$i])
    Write-Host ""
     
    $connection = Connect-HPEBIOS -IP $ListOfAddress[$i] -Credential $Credential -DisableCertificateAuthentication

    if($connection -ne $null)
     {  
        Write-Host ""
        Write-Host ("Connection established to the server {0}") -f $ListOfAddress[$i] -ForegroundColor Green
        $connection
        if($connection.TargetInfo.ProductName.Contains("Gen9") -or $connection.TargetInfo.ProductName.Contains("Gen10"))
        {
            $ListOfConnection += $connection
        }
        else
        {
            Write-Host "BIOS Admin Password is not supported on Server $($connection.IP)"
            Disconnect-HPEBIOS -Connection $connection
        }
    }
    else
    {
        Write-Host "Connection cannot be established to the server : $($ListOfAddress[$i])" -ForegroundColor Red
    }
} 

if($ListOfConnection.Count -eq 0)
{
    Write-Host "Exit.."
    Write-Host ""
    exit
}
# Take user input for AdminPassword

if($AdminPassword.Count -eq 0)
{
    $tempAdminPassword = Read-Host "Enter admin password"
    $AdminPassword = $tempAdminPassword.Split(',')
    if($AdminPassword.Count -eq 0)
    {
        Write-host "Admin password is not provided`n Exit....."
        Exit
    }
}


Write-Host "Configuring the AdminPassword....." -ForegroundColor Green
Write-Host " "

$failureCount = 0
if($ListOfConnection.Count -ne 0)
{
   
   $setResult =  Set-HPEBIOSAdminPassword -Connection $ListOfConnection -OldAdminPassword "" -NewAdminPassword $AdminPassword -ErrorAction Continue
   
   foreach($result in $setResult)
   {
    if($result.Status -eq "Information")
    {
        $result
         Write-host "AdminPassword set successfully " $($result.IP)  -ForegroundColor Green
        if($RestartSever){
            $serverRestart = Reset-HPiLOServer -Server $($ListOfConnection[$i].IP) -Credential $Credential -DisableCertificateAuthentication

            if($serverRestart.STATUS_MESSAGE -contains "Server being reset."){
                Write-Host "Server $($ListOfConnection[$i].IP) being reset....." -ForegroundColor Green
                Write-Host ""
            }
        }
    }
    elseif($result.Status -eq "Error")
    {
        Write-Host ""
        Write-Host "AdminPassword cannot be set"
        Write-Host "Server : $($result.IP)"
        Write-Host "Error : $($result.StatusInfo)"
		Write-Host "StatusInfo.Category : $($result.StatusInfo.Category)"
		Write-Host "StatusInfo.Message : $($result.StatusInfo.Message)"
		Write-Host "StatusInfo.AffectedAttribute : $($result.StatusInfo.AffectedAttribute)"
        $failureCount++
    }
   }
}
    
Disconnect-HPEBIOS -Connection $ListOfConnection
$ErrorActionPreference = "Continue"
Write-Host "******Script execution completed******" -ForegroundColor Green
exit





# SIG # Begin signature block
# MIIjEQYJKoZIhvcNAQcCoIIjAjCCIv4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDpVt/FBaaEeJgi
# etDzVZth3XEDBkP/6VA1KbxwEmN+iqCCHhkwggViMIIESqADAgECAhEA1HaTOoqh
# lf5Gt0z/XIj9PzANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJHQjEbMBkGA1UE
# CBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxJDAiBgNVBAMTG1NlY3RpZ28gUlNBIENvZGUgU2ln
# bmluZyBDQTAeFw0yMDAxMjkwMDAwMDBaFw0yMTAxMjgyMzU5NTlaMIHSMQswCQYD
# VQQGEwJVUzEOMAwGA1UEEQwFOTQzMDQxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlQ
# YWxvIEFsdG8xHDAaBgNVBAkMEzMwMDAgSGFub3ZlciBTdHJlZXQxKzApBgNVBAoM
# Ikhld2xldHQgUGFja2FyZCBFbnRlcnByaXNlIENvbXBhbnkxGjAYBgNVBAsMEUhQ
# IEN5YmVyIFNlY3VyaXR5MSswKQYDVQQDDCJIZXdsZXR0IFBhY2thcmQgRW50ZXJw
# cmlzZSBDb21wYW55MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvx6k
# Tl1QwY5TPYjtfizxfnoPN5p5ww8eS2bphLytlwcYK3+gaZ53iSzma2e2M9b5vj6p
# hTwUaY6Nb73Z7mho270Ze/fhCmPEPi2lEJSkj+iGSlrFGDnxOEM6YIqtT8615kE7
# CUVgQDxq7nOAgJFxA7BgIJPr9wssh5ix3cnJL6WrYIlmGe9+zgeoyhq98vU9D4Oa
# dUfuXXpRhXQBq3odyXE7BAADShVrFtOmc8zgBlk3iuvpBaX2M4vVEuckJK+IQ8lP
# 3iVo7GbpFjKXneh3JcnxHy+cHbN1zkbj1BkfysuLXylswWB8BWQbHZpUD7Ck/XbE
# wvWlwnMBg21oTG8FPQIDAQABo4IBhjCCAYIwHwYDVR0jBBgwFoAUDuE6qFM6MdWK
# vsG7rWcaA4WtNA4wHQYDVR0OBBYEFNEUNOlei+sYBxYNcJwz3uwND2/2MA4GA1Ud
# DwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEG
# CWCGSAGG+EIBAQQEAwIEEDBABgNVHSAEOTA3MDUGDCsGAQQBsjEBAgEDAjAlMCMG
# CCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzBDBgNVHR8EPDA6MDig
# NqA0hjJodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29SU0FDb2RlU2lnbmlu
# Z0NBLmNybDBzBggrBgEFBQcBAQRnMGUwPgYIKwYBBQUHMAKGMmh0dHA6Ly9jcnQu
# c2VjdGlnby5jb20vU2VjdGlnb1JTQUNvZGVTaWduaW5nQ0EuY3J0MCMGCCsGAQUF
# BzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG9w0BAQsFAAOCAQEA
# HV/3fBUIKpntI8lNEkiH4b1Yg/gFHbdwhtJBV4LTAvhtknuzyPXYvbC+f7STvvRh
# 4AtpTQtV4YYDrT/u5dxZUOcoQBVxZzeF32CwIq/N37H96UrMDCEvj/BZjpALrojX
# lDsUwigaC9cggeEs3qr4jUffTL1u/wQyri0BSKuRSFkvkVFnzyG09g3JoJz3K1MD
# WM7NDQZwoTJfrkkGMDabtrD+4dniZ9lgeryBNYJoQ9Xmxe9MbyiGXNPGlwhMSMEF
# /8m4aVVaWn7an5+NuFg/etiEVMe1kwFzV18j5YKYdAQAQ/MVuJeRXSmjrARPXslq
# Y3m0OLx6TeshBO1B7J0Y7jCCBXcwggRfoAMCAQICEBPqKHBb9OztDDZjCYBhQzYw
# DQYJKoZIhvcNAQEMBQAwbzELMAkGA1UEBhMCU0UxFDASBgNVBAoTC0FkZFRydXN0
# IEFCMSYwJAYDVQQLEx1BZGRUcnVzdCBFeHRlcm5hbCBUVFAgTmV0d29yazEiMCAG
# A1UEAxMZQWRkVHJ1c3QgRXh0ZXJuYWwgQ0EgUm9vdDAeFw0wMDA1MzAxMDQ4Mzha
# Fw0yMDA1MzAxMDQ4MzhaMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEpl
# cnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJV
# U1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJTQSBDZXJ0aWZpY2F0aW9u
# IEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAIASZRc2
# DsPbCLPQrFcNdu3NJ9NMrVCDYeKqIE0JLWQJ3M6Jn8w9qez2z8Hc8dOx1ns3KBEr
# R9o5xrw6GbRfpr19naNjQrZ28qk7K5H44m/Q7BYgkAk+4uh0yRi0kdRiZNt/owbx
# iBhqkCI8vP4T8IcUe/bkH47U5FHGEWdGCFHLhhRUP7wz/n5snP8WnRi9UY41pqdm
# yHJn2yFmsdSbeAPAUDrozPDcvJ5M/q8FljUfV1q3/875PbcstvZU3cjnEjpNrkyK
# t1yatLcgPcp/IjSufjtoZgFE5wFORlObM2D3lL5TN5BzQ/Myw1Pv26r+dE5px2uM
# YJPexMcM3+EyrsyTO1F4lWeL7j1W/gzQaQ8bD/MlJmszbfduR/pzQ+V+DqVmsSl8
# MoRjVYnEDcGTVDAZE6zTfTen6106bDVc20HXEtqpSQvf2ICKCZNijrVmzyWIzYS4
# sT+kOQ/ZAp7rEkyVfPNrBaleFoPMuGfi6BOdzFuC00yz7Vv/3uVzrCM7LQC/NVV0
# CUnYSVgaf5I25lGSDvMmfRxNF7zJ7EMm0L9BX0CpRET0medXh55QH1dUqD79dGMv
# sVBlCeZYQi5DGky08CVHWfoEHpPUJkZKUIGy3r54t/xnFeHJV4QeD2PW6WK61l9V
# LupcxigIBCU5uA4rqfJMlxwHPw1S9e3vL4IPAgMBAAGjgfQwgfEwHwYDVR0jBBgw
# FoAUrb2YejS0Jvf6xCZU7wO94CTLVBowHQYDVR0OBBYEFFN5v1qqK0rPVIDh2JvA
# nfKyA2bLMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MBEGA1UdIAQK
# MAgwBgYEVR0gADBEBgNVHR8EPTA7MDmgN6A1hjNodHRwOi8vY3JsLnVzZXJ0cnVz
# dC5jb20vQWRkVHJ1c3RFeHRlcm5hbENBUm9vdC5jcmwwNQYIKwYBBQUHAQEEKTAn
# MCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3
# DQEBDAUAA4IBAQCTZfY3g5UPXsOCHB/Wd+c8isCqCfDpCybx4MJqdaHHecm5UmDI
# KRIO8K0D1gnEdt/lpoGVp0bagleplZLFto8DImwzd8F7MhduB85aFEE6BSQb9hQG
# O6glJA67zCp13blwQT980GM2IQcfRv9gpJHhZ7zeH34ZFMljZ5HqZwdrtI+LwG5D
# fcOhgGyyHrxThX3ckKGkvC3vRnJXNQW/u0a7bm03mbb/I5KRxm5A+I8pVupf1V8U
# U6zwT2Hq9yLMp1YL4rg0HybZexkFaD+6PNQ4BqLT5o8O47RxbUBCxYS0QJUr9GWg
# SHn2HYFjlp1PdeD4fOSOqdHyrYqzjMchzcLvMIIF9TCCA92gAwIBAgIQHaJIMG+b
# JhjQguCWfTPTajANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVU
# aGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2Vy
# dGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTgxMTAyMDAwMDAwWhcNMzAxMjMxMjM1
# OTU5WjB8MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJDAi
# BgNVBAMTG1NlY3RpZ28gUlNBIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAIYijTKFehifSfCWL2MIHi3cfJ8Uz+MmtiVmKUCG
# VEZ0MWLFEO2yhyemmcuVMMBW9aR1xqkOUGKlUZEQauBLYq798PgYrKf/7i4zIPoM
# GYmobHutAMNhodxpZW0fbieW15dRhqb0J+V8aouVHltg1X7XFpKcAC9o95ftanK+
# ODtj3o+/bkxBXRIgCFnoOc2P0tbPBrRXBbZOoT5Xax+YvMRi1hsLjcdmG0qfnYHE
# ckC14l/vC0X/o84Xpi1VsLewvFRqnbyNVlPG8Lp5UEks9wO5/i9lNfIi6iwHr0bZ
# +UYc3Ix8cSjz/qfGFN1VkW6KEQ3fBiSVfQ+noXw62oY1YdMCAwEAAaOCAWQwggFg
# MB8GA1UdIwQYMBaAFFN5v1qqK0rPVIDh2JvAnfKyA2bLMB0GA1UdDgQWBBQO4Tqo
# Uzox1Yq+wbutZxoDha00DjAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB
# /wIBADAdBgNVHSUEFjAUBggrBgEFBQcDAwYIKwYBBQUHAwgwEQYDVR0gBAowCDAG
# BgRVHSAAMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwudXNlcnRydXN0LmNv
# bS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDB2BggrBgEF
# BQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRydXN0LmNvbS9V
# U0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEFBQcwAYYZaHR0cDovL29j
# c3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEATWNQ7Uc0SmGk295q
# Koyb8QAAHh1iezrXMsL2s+Bjs/thAIiaG20QBwRPvrjqiXgi6w9G7PNGXkBGiRL0
# C3danCpBOvzW9Ovn9xWVM8Ohgyi33i/klPeFM4MtSkBIv5rCT0qxjyT0s4E307dk
# sKYjalloUkJf/wTr4XRleQj1qZPea3FAmZa6ePG5yOLDCBaxq2NayBWAbXReSnV+
# pbjDbLXP30p5h1zHQE1jNfYw08+1Cg4LBH+gS667o6XQhACTPlNdNKUANWlsvp8g
# JRANGftQkGG+OY96jk32nw4e/gdREmaDJhlIlc5KycF/8zoFm/lv34h/wCOe0h5D
# ekUxwZxNqfBZslkZ6GqNKQQCd3xLS81wvjqyVVp4Pry7bwMQJXcVNIr5NsxDkuS6
# T/FikyglVyn7URnHoSVAaoRXxrKdsbwcCtp8Z359LukoTBh+xHsxQXGaSynsCz1X
# UNLK3f2eBVHlRHjdAd6xdZgNVCT98E7j4viDvXK6yz067vBeF5Jobchh+abxKgoL
# pbn0nu6YMgWFnuv5gynTxix9vTp3Los3QqBqgu07SqqUEKThDfgXxbZaeTMYkuO1
# dfih6Y4KJR7kHvGfWocj/5+kUZ77OYARzdu1xKeogG/lU9Tg46LC0lsa+jImLWpX
# cBw8pFguo/NbSwfcMlnzh6cabVgwggZqMIIFUqADAgECAhADAZoCOv9YsWvW1erm
# F/BmMA0GCSqGSIb3DQEBBQUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdp
# Q2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERp
# Z2lDZXJ0IEFzc3VyZWQgSUQgQ0EtMTAeFw0xNDEwMjIwMDAwMDBaFw0yNDEwMjIw
# MDAwMDBaMEcxCzAJBgNVBAYTAlVTMREwDwYDVQQKEwhEaWdpQ2VydDElMCMGA1UE
# AxMcRGlnaUNlcnQgVGltZXN0YW1wIFJlc3BvbmRlcjCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAKNkXfx8s+CCNeDg9sYq5kl1O8xu4FOpnx9kWeZ8a39r
# jJ1V+JLjntVaY1sCSVDZg85vZu7dy4XpX6X51Id0iEQ7Gcnl9ZGfxhQ5rCTqqEss
# kYnMXij0ZLZQt/USs3OWCmejvmGfrvP9Enh1DqZbFP1FI46GRFV9GIYFjFWHeUhG
# 98oOjafeTl/iqLYtWQJhiGFyGGi5uHzu5uc0LzF3gTAfuzYBje8n4/ea8EwxZI3j
# 6/oZh6h+z+yMDDZbesF6uHjHyQYuRhDIjegEYNu8c3T6Ttj+qkDxss5wRoPp2kCh
# WTrZFQlXmVYwk/PJYczQCMxr7GJCkawCwO+k8IkRj3cCAwEAAaOCAzUwggMxMA4G
# A1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMIIBvwYDVR0gBIIBtjCCAbIwggGhBglghkgBhv1sBwEwggGSMCgGCCsGAQUF
# BwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMIIBZAYIKwYBBQUHAgIw
# ggFWHoIBUgBBAG4AeQAgAHUAcwBlACAAbwBmACAAdABoAGkAcwAgAEMAZQByAHQA
# aQBmAGkAYwBhAHQAZQAgAGMAbwBuAHMAdABpAHQAdQB0AGUAcwAgAGEAYwBjAGUA
# cAB0AGEAbgBjAGUAIABvAGYAIAB0AGgAZQAgAEQAaQBnAGkAQwBlAHIAdAAgAEMA
# UAAvAEMAUABTACAAYQBuAGQAIAB0AGgAZQAgAFIAZQBsAHkAaQBuAGcAIABQAGEA
# cgB0AHkAIABBAGcAcgBlAGUAbQBlAG4AdAAgAHcAaABpAGMAaAAgAGwAaQBtAGkA
# dAAgAGwAaQBhAGIAaQBsAGkAdAB5ACAAYQBuAGQAIABhAHIAZQAgAGkAbgBjAG8A
# cgBwAG8AcgBhAHQAZQBkACAAaABlAHIAZQBpAG4AIABiAHkAIAByAGUAZgBlAHIA
# ZQBuAGMAZQAuMAsGCWCGSAGG/WwDFTAfBgNVHSMEGDAWgBQVABIrE5iymQftHt+i
# vlcNK2cCzTAdBgNVHQ4EFgQUYVpNJLZJMp1KKnkag0v0HonByn0wfQYDVR0fBHYw
# dDA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJl
# ZElEQ0EtMS5jcmwwOKA2oDSGMmh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydEFzc3VyZWRJRENBLTEuY3JsMHcGCCsGAQUFBwEBBGswaTAkBggrBgEFBQcw
# AYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAChjVodHRwOi8v
# Y2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURDQS0xLmNydDAN
# BgkqhkiG9w0BAQUFAAOCAQEAnSV+GzNNsiaBXJuGziMgD4CH5Yj//7HUaiwx7ToX
# GXEXzakbvFoWOQCd42yE5FpA+94GAYw3+puxnSR+/iCkV61bt5qwYCbqaVchXTQv
# H3Gwg5QZBWs1kBCge5fH9j/n4hFBpr1i2fAnPTgdKG86Ugnw7HBi02JLsOBzppLA
# 044x2C/jbRcTBu7kA7YUq/OPQ6dxnSHdFMoVXZJB2vkPgdGZdA0mxA5/G7X1oPHG
# dwYoFenYk+VVFvC7Cqsc21xIJ2bIo4sKHOWV2q7ELlmgYd3a822iYemKC23sEhi9
# 91VUQAOSK2vCUcIKSK+w1G7g9BQKOhvjjz3Kr2qNe9zYRDCCBs0wggW1oAMCAQIC
# EAb9+QOWA63qAArrPye7uhswDQYJKoZIhvcNAQEFBQAwZTELMAkGA1UEBhMCVVMx
# FTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNv
# bTEkMCIGA1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTA2MTEx
# MDAwMDAwMFoXDTIxMTExMDAwMDAwMFowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoT
# DERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UE
# AxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEA6IItmfnKwkKVpYBzQHDSnlZUXKnE0kEGj8kz/E1FkVyBn+0s
# nPgWWd+etSQVwpi5tHdJ3InECtqvy15r7a2wcTHrzzpADEZNk+yLejYIA6sMNP4Y
# SYL+x8cxSIB8HqIPkg5QycaH6zY/2DDD/6b3+6LNb3Mj/qxWBZDwMiEWicZwiPkF
# l32jx0PdAug7Pe2xQaPtP77blUjE7h6z8rwMK5nQxl0SQoHhg26Ccz8mSxSQrllm
# CsSNvtLOBq6thG9IhJtPQLnxTPKvmPv2zkBdXPao8S+v7Iki8msYZbHBc63X8djP
# Hgp0XEK4aH631XcKJ1Z8D2KkPzIUYJX9BwSiCQIDAQABo4IDejCCA3YwDgYDVR0P
# AQH/BAQDAgGGMDsGA1UdJQQ0MDIGCCsGAQUFBwMBBggrBgEFBQcDAgYIKwYBBQUH
# AwMGCCsGAQUFBwMEBggrBgEFBQcDCDCCAdIGA1UdIASCAckwggHFMIIBtAYKYIZI
# AYb9bAABBDCCAaQwOgYIKwYBBQUHAgEWLmh0dHA6Ly93d3cuZGlnaWNlcnQuY29t
# L3NzbC1jcHMtcmVwb3NpdG9yeS5odG0wggFkBggrBgEFBQcCAjCCAVYeggFSAEEA
# bgB5ACAAdQBzAGUAIABvAGYAIAB0AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEA
# dABlACAAYwBvAG4AcwB0AGkAdAB1AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMA
# ZQAgAG8AZgAgAHQAaABlACAARABpAGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMA
# IABhAG4AZAAgAHQAaABlACAAUgBlAGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEA
# ZwByAGUAZQBtAGUAbgB0ACAAdwBoAGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEA
# YgBpAGwAaQB0AHkAIABhAG4AZAAgAGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEA
# dABlAGQAIABoAGUAcgBlAGkAbgAgAGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4w
# CwYJYIZIAYb9bAMVMBIGA1UdEwEB/wQIMAYBAf8CAQAweQYIKwYBBQUHAQEEbTBr
# MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUH
# MAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2lj
# ZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6
# Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmww
# HQYDVR0OBBYEFBUAEisTmLKZB+0e36K+Vw0rZwLNMB8GA1UdIwQYMBaAFEXroq/0
# ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBBQUAA4IBAQBGUD7Jtygkpzgdtlsp
# r1LPUukxR6tWXHvVDQtBs+/sdR90OPKyXGGinJXDUOSCuSPRujqGcq04eKx1XRcX
# NHJHhZRW0eu7NoR3zCSl8wQZVann4+erYs37iy2QwsDStZS9Xk+xBdIOPRqpFFum
# hjFiqKgz5Js5p8T1zh14dpQlc+Qqq8+cdkvtX8JLFuRLcEwAiR78xXm8TBJX/l/h
# HrwCXaj++wc4Tw3GXZG5D2dFzdaD7eeSDY2xaYxP+1ngIw/Sqq4AfO6cQg7Pkdcn
# txbuD8O9fAqg7iwIVYUiuOsYGk38KiGtSTGDR5V3cdyxG0tLHBCcdxTBnU8vWpUI
# KRAmMYIETjCCBEoCAQEwgZEwfDELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0
# ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGln
# byBMaW1pdGVkMSQwIgYDVQQDExtTZWN0aWdvIFJTQSBDb2RlIFNpZ25pbmcgQ0EC
# EQDUdpM6iqGV/ka3TP9ciP0/MA0GCWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIB
# DDECMAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJSDUB1CgTs7NAeMvrpleU2L
# 1ElTx7yH0ihckaOhTAiPMA0GCSqGSIb3DQEBAQUABIIBAFS8h1jHmlFkSz02XyLm
# rZvfYzAv9SzUHe/lBrgnXvN7d2fJold+/PXcrkr2mGxWVXa3VZw4775yVuxYp5Kv
# UEAvsNU62+EO0AyuvcAYKNAztPGot88CWA1N5iXEz191UXGU4zhA3ZYWNGW9VCB1
# EvCsBdbNszFjVGbjXMEjJ7mFkLUkx5hRO/dwZ5l8fXRWdcJJOp78835WqPtaZHK8
# bxDzZAgLQFevUGaiSCGuYK7AoCw+Wr05DbESifkfxswtsJvw/sHwKpW3zfmS2SFj
# 5W9e9VM66ndmvKtS2ee0VVsYoC17Jq+0b/h8IQL7mQS+UaK7dDltu5NntyVmwLXU
# 6lyhggIPMIICCwYJKoZIhvcNAQkGMYIB/DCCAfgCAQEwdjBiMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTECEAMBmgI6/1ix
# a9bV6uYX8GYwCQYFKw4DAhoFAKBdMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEw
# HAYJKoZIhvcNAQkFMQ8XDTIwMDUxODExNDkzMVowIwYJKoZIhvcNAQkEMRYEFPNi
# NUQnkOwjK6tLOZpMYD6kKx3lMA0GCSqGSIb3DQEBAQUABIIBAIiGx6+6Jrp3tA8s
# I3xSF5Qudoqu25Wy+r1nVuJUA/Gako5XOKiCP+VcoKL2/xfaZFOs8IvY4kLjKqHj
# QlDuSwqDa2iaSTAILDLs7Q37KMazxYcTpWnPjoFuWhBg6VOkAB4JBySnhja979oR
# AVgKUUG3vxyQnQSzYVssBDHF/F9tF09KRdZ5vQSlXHiva70oMXOFdpxbpnK6iQty
# JiWZlwmcO3rtg+6aa/HcsfraPZnN3rZyTgjJ8ymOE26Wd4/oKOG2TxaLDGVkb3pb
# PRUM+mC92P501DZ26e+VAobg++dcx6Ek8Ng9Tr8qiCa7qyyogeWYvIzXtUfX+mjm
# phFXLgQ=
# SIG # End signature block
