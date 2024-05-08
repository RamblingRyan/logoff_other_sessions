Function Get-Sessions {
    Param (
        $ComputerName
    )
    $i = 0
    IF ($ComputerName) {
        $sessions = quser /server:$ComputerName
    } ELSE {
        $sessions = quser
    }
    $sessions | ForEach-Object {
        IF ($i -ne 0) {
            $_ -replace "Disc","Disconnected" -match '^[\s>]([\w\.]+)\s+(\brdp-tcp#\b\d\d|\bconsole\b|\s)\s+(\d+)\s+(\w+)\s+([\d+:\.|\bnone\b]+)\s+([\d\/\s:]+)$' | Out-Null
            #$Report = "" | Select-Object ComputerName,UserName,SessionName,ID,State,IdleTime,LogonTime
            $Report = New-Object psobject
            IF ($ComputerName) {
                # $Report.ComputerName = $ComputerName
                Add-Member -InputObject $Report -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
            } ELSE {
                # $Report.ComputerName = "localhost"
                Add-Member -InputObject $Report -MemberType NoteProperty -Name "ComputerName" -Value "localhost"
            }
            # $Report.UserName = $matches[1]
            Add-Member -InputObject $Report -MemberType NoteProperty -Name "UserName" -Value $matches[1]
            # $Report.SessionName = $matches[2]
            Add-Member -InputObject $Report -MemberType NoteProperty -Name "SessionName" -Value $matches[2]
            # $Report.ID = [int]($matches[3])
            Add-Member -InputObject $Report -MemberType NoteProperty -Name "ID" -Value ([int]($matches[3]))
            # $Report.State = $matches[4]
            Add-Member -InputObject $Report -MemberType NoteProperty -Name "State" -Value $matches[4]
            IF ($matches[5] -ne "none") {
                # $Report.IdleTime = $matches[5] -replace "\+"," Days, " -replace ":"," Hours and " -replace '$'," Minutes"
                Add-Member -InputObject $Report -MemberType NoteProperty -Name "IdleTime" -Value ($matches[5] -replace "\+"," Days, " -replace ":"," Hours and " -replace '$'," Minutes")
            }
            # $Report.LogonTime = $matches[6]
            $CultureDateTimeFormat = (Get-Culture).DateTimeFormat
            $DateFormat = $CultureDateTimeFormat.ShortDatePattern
            $TimeFormat = $CultureDateTimeFormat.ShortTimePattern
            $DateTimeFormat = "$DateFormat $TimeFormat"
            Add-Member -InputObject $Report -MemberType NoteProperty -Name "LogonTime" -Value ([datetime]::ParseExact($matches[6],$DateTimeFormat,[System.Globalization.DateTimeFormatInfo]::InvariantInfo,[System.Globalization.DateTimeStyles]::None))
            $Report
        }
        $i++
    }
}


if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
  "Restart as admin"
  $arguments = "& '" +$myinvocation.mycommand.definition + "'"
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  Break
} else {
  "Already admin"
}


$ThisUser = $env:USERNAME
"You are user name " + $ThisUser

"**** Sesions Before *****"
$Sessions = Get-Sessions
$Sessions


foreach ($Session in $Sessions) {
    "Session ID " + $Session.ID
    "UserName " + $Session.UserName
    if ($Session.UserName -like $ThisUser) {
        "That is me"
    } else {
        "Better logoff session " + $Session.ID
        logoff $Session.ID
    }
}

""
"***** Sesssions After ****"
$Sessions = Get-Sessions
$Sessions

"Press any key to close. Or will close automatically in 10 seconds"
$counter = 0
while (!$Host.UI.RawUI.KeyAvailable -and ($counter++ -lt 10)) {
    Start-Sleep -Seconds 1
}
