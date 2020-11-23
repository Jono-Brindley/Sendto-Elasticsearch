Remove-Variable * -ErrorAction SilentlyContinue

Function Sendto-Elasticsearch
{

Function Calc-LoginTime{
    $explorer = (Get-Date (Get-Process explorer).StartTime)

    $script:timeBegin = (Get-WinEvent -FilterHashTable @{LogName="System";Id=7001;StartTime=(Get-Date).AddDays(-10)} -MaxEvents 1).TimeCreated
    $script:logonTime =  $explorer - $timeBegin
}

Function GenFakeLoginTime{
for ($i=0; $i-le 10; $i++)
    {
        [array]$loginTimeFalse += 30 + (get-random 32)
    }
}

Function GatherData{

}

Function AddData{

#$timeStamp = (Get-Date).ToString("dd/MM/yy")
$userName = $env:USERNAME
$hostName = $env:COMPUTERNAME
$logindata = (Get-WinEvent -FilterHashTable @{LogName="System";StartTime=(Get-Date).AddDays(-10)} -MaxEvents 1).MachineName
$OSVers = [environment]::OSVersion.Version | Select Major, Minor, Build

$script:data = $null
$script:data = @{
#TimeStamp = $timeStamp;
UserName = $userName;
HostName = $hostName;
MachineName = $logindata;
OSVersion = $OSVers;
TimeToLogin = [System.Math]::Round($logonTime.TotalSeconds);
LoginTime = $timeBegin.ToString("HH:mm:ss dd/MM/yy");
} | ConvertTo-Json
echo $data

}

Function SendData{

#Invoke-WebRequest -Uri http://slazls03.westeurope.cloudapp.azure.com:8080 -Method POST  -Body $data
echo `n "-----Done!-----"
}

Calc-LoginTime
#GatherData
#GenFakeLoginTime
AddData
SendData

}

Sendto-Elasticsearch