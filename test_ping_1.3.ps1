# Описание
# Скрипт работает через джобы в многопоточном режиме
# Версия 1.3
# Дата 14.09.2018

[string]$global:known_host_ip= "0.0.0.0"
[string]$global:mask_ip = "0.0.0.0"
$Global:Version = 0
[int]$Threads = 5 ## количество потоков для пинговалки
$Hosts = @{}
[int]$Timeout = 1


function OutLocalInfo {
    #получить и вывести инфу о локальном хосте
    $host_name = 'localhost'
    Write-Output "Start scanner script, version is $Global:Version."
    Write-Output "Time starting: $(get-date -format F)"
    $cur_host = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=$true -ComputerName $host_name | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS* #| select-Object -Property IPAddress, MACAddress, IPSubnet
    Write-Output "Local system: $host_name"
    Write-Output ('Ip address: ' + $cur_host.IPAddress[0])
    Write-Output ('MAC address: ' + $cur_host.MACAddress)
    Write-Output ('Subnet mask: ' + $cur_host.IPSubnet[0])
    Write-Output ('Default gateway: ' + $cur_host.DefaultIPGateway)
    Write-Output ('DNS host name: ' + $cur_host.DNSHostName)
    Write-Output ('Domain: ' + $cur_host.DNSDomain)
    $global:known_host_ip = $cur_host.IPAddress[0]
    $global:mask_ip = $cur_host.IPSubnet[0]
    $CustomObject = New-Object –TypeName PSObject
    $CustomObject | Add-Member –MemberType NoteProperty –Name IPAddress –Value $cur_host.IPAddress[0]
    $CustomObject | Add-Member –MemberType NoteProperty –Name MACAddress –Value $cur_host.cur_host.MACAddress
    $CustomObject | Add-Member –MemberType NoteProperty –Name DNSHostName –Value $cur_host.cur_host.DNSHostName
    $CustomObject
} # end function OutLocalInfo

Function ScanSubNet {
    param (
        [string[]]$Address, 
        [int]$Timeout
    )
    #Создаём объект $pinger, который и будет делать всё самое главное :)
    $pinger = New-Object system.net.networkinformation.ping
    #Устанавливаем поведение при ошибке - продолжать и не выводить ошибку на экран
    $ErrorActionPreference = "SilentlyContinue"
    #Для каждого хоста в массиве $Address...
    foreach ($Host_i in $Address) {
        #Посылаем ping, и сохраняем результат в переменной $res
        $res = $pinger.Send($Host_i,($Timeout*1000))
        #Если пинг успешен, то
        if ($res.Status -eq "Success")
        {
            #Устанавливаем значение равным времени отклика
            $TimeOut_e = $res.RoundtripTime
            $mac_e = Get-MAC $Host_i
            #$Value = $mac_e
            $Hosts[$Host_i] = $mac_e
        }
        else
        {
            #Иначе - указываем в значении статус
            $Value = $res.status
        }
    }
    $Hosts
} # end of function ScanSubNet

function Get-IPrange
{
<# 
  .SYNOPSIS  
    Get the IP addresses in a range 
  .EXAMPLE 
   Get-IPrange -start 192.168.8.2 -end 192.168.8.20 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.2 -mask 255.255.255.0 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.3 -cidr 24 
#> 
 param 
( 
  [string]$start, 
  [string]$end, 
  [string]$ip, 
  [string]$mask, 
  [int]$cidr 
) 
$add_net_brcast = 1 #учитывать адреса сети и броадкаста
 
function IP-toINT64 () { 
  param ($ip) 
  $octets = $ip.split(".") 
  return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
} 
 
function INT64-toIP() { 
  param ([int64]$int) 
  return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
} 
 
if ($ip) {$ipaddr = [Net.IPAddress]::Parse($ip)} 
if ($cidr) {$maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2)))) } 
if ($mask) {$maskaddr = [Net.IPAddress]::Parse($mask)} 
if ($ip) {$networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)} 
if ($ip) {$broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))} 
 
if ($ip) { 
  $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring 
  $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring 
} else { 
  $startaddr = IP-toINT64 -ip $start 
  $endaddr = IP-toINT64 -ip $end 
} 
    for ($i = $startaddr + $add_net_brcast; $i -le $endaddr - $add_net_brcast; $i++) 
    { 
        INT64-toIP -int $i
    }

} # end function Get-IPrange

Function Get-DNSName ($IP) {
    (Resolve-DnsName -Name $IP -ErrorAction SilentlyContinue).NameHost
}# end Function Get-DNSName

Function Get-MAC ($IP) {
    $Cmd_Arp_Out=arp -a | Where-Object {$_.Contains("$IP ")}
    if ($Cmd_Arp_Out -ne $NULL) {
      $HW_Addr=$Cmd_Arp_Out.Substring(24,17)
    }
  $HW_Addr
}#end function Get-MAC

function GetConfiguration {
    $ConfigFileName = "config.xml"
    [xml]$obj = Get-Content .\$ConfigFileName
    if ([string]$obj.Root.Part.Version) {
        $Global:Version = [string]$obj.Root.Part.Version
    }
    $ret = 0
    if ([string]$obj.Root.Configuration.Enable) {
        $ret = [string]$obj.Root.Configuration.Enable
    }
    return $ret
}#end function

[string]$EanbleScript = GetConfiguration
if ([int]$EanbleScript -eq $true) {
    OutLocalInfo
    $global:mask_ip = "255.255.255.248" ## temp mask
    #Write-Host "Host IP: $global:known_host_ip"
    #Write-Host "Mask IP: $global:mask_ip"
    [string[]]$Address1 = Get-IPrange -ip $global:known_host_ip -mask $global:mask_ip ## temp

    #Write-Host "Address - $Address1"
    $H = ScanSubNet $Address1 $Timeout

    Write-Host "All count: "  $Address1.count
    write-host "Accessible hosts: " $H.count

    foreach ($Key_1 in $H.Keys) {
        Write-Output($Key_1 + " - " + $H[$Key_1])
    }
}
else {
    write-host "Script Disabled."
}