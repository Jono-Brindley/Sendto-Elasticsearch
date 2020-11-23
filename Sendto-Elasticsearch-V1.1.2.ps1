Remove-Variable * -ErrorAction SilentlyContinue

Function Sendto-Elasticsearch
{

Function Calc-LoginTime{
    try {
        $script:explorer = (Get-Date (Get-Process explorer).StartTime)
        $script:timeBegin = (Get-WinEvent -FilterHashTable @{LogName="System";Id=7001;StartTime=(Get-Date).AddDays(-10)} -MaxEvents 1 -ErrorAction SilentlyContinue).TimeCreated
        $script:logonTime =  $explorer - $timeBegin
    }
    catch {
        Exit
        write-log -message "message" -severityerror
    }
}

Function GatherData{
    #$timeStamp = (Get-Date).ToString("dd/MM/yy")
    $script:userName = $env:USERNAME
    $script:hostName = $env:COMPUTERNAME
    $script:logindata = (Get-WinEvent -FilterHashTable @{LogName="System";StartTime=(Get-Date).AddDays(-10)} -MaxEvents 1).MachineName
    $script:OSVers = [environment]::OSVersion.Version | Select Major, Minor, Build
    $script:hotFix = (Get-HotFix | Select HotFixID, Description | Sort-Object Date)[-1]
    $script:domain = (Get-WMIObject –class Win32_ComputerSystem).Domain
    $script:model = (Get-WMIObject –class Win32_ComputerSystem).Model
    $script:make = (Get-WMIObject –class Win32_ComputerSystem).Manufacturer

}

Function AddData{

    $script:data = $null
    $script:data = @{
    #TimeStamp = $timeStamp;
    UserName = $userName;
    HostName = $hostName;
    MachineName = $logindata;
    OSVersion = $OSVers;
    TimeToLogin = [System.Math]::Round($logonTime.TotalSeconds);
    LoginTime = $timeBegin.ToString("yyyy-MM-dd" + "T" + "HH:mm:ss");
    PatchLevel = $hotFix;
    Domain = $domain;
    Model = $model;
    Make = $make;
    TimeExplorerOpened = $explorer.ToString("yyyy-MM-dd" + "T" + "HH:mm:ss");

} | ConvertTo-Json

    If ($timeBegin -lt 1) { $script:Invalid = $true }
    If ($hostName.Length -lt 11) { $script:Invalid = $true }
    If (($userName.Length -lt 3) -or ($Username.Length -gt 12)) { $script:Invalid = $true }
    If ($logonTime -lt 1) { $script:Invalid = $true }

echo $data

}

Function SendData{
    $testConn = $null
    $testConn = (Get-NetRoute | ? DestinationPrefix -eq '0.0.0.0/0' | Get-NetIPInterface | Where ConnectionState -eq 'Connected').InterfaceAlias

    while ($testConn -eq $null){
        Write-Host "Please connect to the internet" -ForegroundColor Yellow
        Start-Sleep -Seconds 120
        $testConn = Get-NetRoute | ? DestinationPrefix -eq '0.0.0.0/0' | Get-NetIPInterface | Where ConnectionState -eq 'Connected' | select InterfaceAlias
        }

    If ($Invalid) {
        Write-Host `n "Error: Invalid Data" -ForegroundColor Red
        } 
    Else {
        try{
            Invoke-WebRequest -Uri http://slazls03.westeurope.cloudapp.azure.com:8080 -Method POST  -Body $data
            Write-Host `n "Success!" -ForegroundColor Green
           }
    catch{
            Write-Host "Error: could not connect, please check your connection or contact Admin for server status." -ForegroundColor Red
         }

     }
echo `n "-----Done!-----"
}

Calc-LoginTime
GatherData
AddData
SendData

}

Sendto-Elasticsearch