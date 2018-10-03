# Описание
# Скрипт работает через джобы в многопоточном режиме
# Версия 1.6
# Дата 01.10.2018

$Global:Version = 0
[int]$Threads = 5 ## количество потоков для пинговалки
$Hosts = @{}
[int]$Timeout = 1
$OutFileName = 'InventOut.txt'

function GetLocalInfo {
    #получить инфу о локальном хосте
    $host_name = 'localhost'
    $cur_host = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=$true -ComputerName $host_name | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS*
    $Propertys = @{}
    $Propertys.Version          = $Global:Version
    $Propertys.Date             = [string]$(get-date -format F)
    $Propertys.IPaddress        = $cur_host.IPAddress[0]
    $Propertys.MACAddress       = $cur_host.MACAddress
    $Propertys.DNSHostName      = $cur_host.DNSHostName
    $Propertys.IPSubnet         = $cur_host.IPSubnet[0]
    $Propertys.DefaultIPGateway = $cur_host.DefaultIPGateway[0]
    $Propertys.DNSDomain        = $cur_host.DNSDomain
    $Propertys
#    $CustomObject = New-Object -TypeName PSObject -Prop $Propertys
#    $CustomObject | Select-Object IPAddress, IPSubnet, MACAddress, DNSHostName, DefaultIPGateway, DNSDomain
} # end function GetLocalInfo

function OutLocalInfo ($CurObject){
    #вывести инфу о локальном хосте
    Write-Host "Start scanner script, version is $Global:Version."
    Write-Host "Time starting: $(get-date -format F)"
    Write-Host ('Ip address:      ' + $CurObject.IPAddress)
    Write-Host ('MAC address:     ' + $CurObject.MACAddress)
    Write-Host ('Subnet mask:     ' + $CurObject.IPSubnet)
    Write-Host ('Default gateway: ' + $CurObject.DefaultIPGateway)
    Write-Host ('DNS host name:   ' + $CurObject.DNSHostName)
    Write-Host ('Domain:          ' + $CurObject.DNSDomain)
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
    $ErrorActionPreference = "SilentlyContinue"
    [xml]$obj = Get-Content .\$ConfigFileName
    if(!$obj) {
        Write-Host "Error: Configuration file is not found."
        return 0
    }
    if ([string]$obj.Root.Part.Version) {
        $Global:Version = [string]$obj.Root.Part.Version
    }

    if ([string]$obj.Root.Part.Debug) {
        $DebugPreference = 'Continue'
    }
    $ret = 0
    if ([string]$obj.Root.Configuration.Enable) {
        $ret = [string]$obj.Root.Configuration.Enable
    }
    return $ret
}#end function

function ConvertTo-Json20([object] $item){
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    return ,$ps_js.Serialize($item)
}

function ConvertFrom-Json20([object] $item){ 
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer

    #The comma operator is the array construction operator in PowerShell
    return ,$ps_js.DeserializeObject($item)
} 

function OutListIPAddress ($Hosts) {
#    $Hosts[$LocalInfo.IPAddress] = $LocalInfo.MACAddress
    foreach ($Key_1 in $Hosts.Keys) {
        $Value1 = [string]$Hosts[$Key_1]
        Write-host "$Key_1 - $Value1"
    }
}

[string]$EanbleScript = GetConfiguration
if ([int]$EanbleScript -eq $true) {
    $JSONStartStr = '{"LocalInfo": '
    $JSONMidleStr = ', "ListIPAddress": '
    $JSONEndStr   = '}'
    $LocalInfo = GetLocalInfo
    OutLocalInfo $LocalInfo
    
    $ObjJSON = $JSONStartStr 
    $ObjJSON += ConvertTo-Json20 $LocalInfo
    $ObjJSON += $JSONMidleStr
    

    #$mask_ip = $LocalInfo.MACAddress
    $mask_ip = "255.255.255.240" ## temp mask
    [string[]]$Address1 = Get-IPrange -ip $LocalInfo.IPAddress -mask $mask_ip ## temp

    $Hosts = ScanSubNet $Address1 $Timeout

    Write-Host "All count: "  $Address1.count
    write-host "Accessible hosts: " $Hosts.count
#    Write-Host $Hosts.gettype().fullname
#    Write-Host $Hosts
    $Hosts[$LocalInfo.IPAddress] = $LocalInfo.MACAddress
    $ObjJSON += ConvertTo-Json20 $Hosts
    $ObjJSON += $JSONEndStr
    $ObjJSON | Set-Content $OutFileName 
    OutListIPAddress $Hosts
}
else {
    write-host "Script Disabled."
}