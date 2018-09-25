# Описание
# Скрипт работает через джобы в многопоточном режиме
# Версия 1.1
# Дата 11.09.2018

$Version = 0.1

#Param (
#[string[]]$Address = $(1..12 | %{"10.124.1.$_"}),
#[int]$Threads = 5
#)            

[int]$Threads = 5 ## количество потоков для пинговалки
#$known_host_ip = "10.124.1.2"
#$mask_ip = "255.255.255.240"
$host_name = 'localhost'

Write-Output "Start scanner."
$cur_host = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=$true -ComputerName $host_name | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS* | select-Object -Property IPAddress, MACAddress, IPSubnet
$ip_addr_host = $cur_host.IPAddress[0]
Write-Output "Local system:"
Write-Output ('Ip address: ' + $ip_addr_host)
Write-Output ('MAC address: ' + $cur_host.MACAddress)
Write-Output ('Subnet mask: ' + $cur_host.IPSubnet[0])
Write-Output ('Default gateway' + $cur_host.DefaultIPGateway)
Write-Output ('DNS host name: ' + $cur_host.DNSHostName)
Write-Output ('Domain: ' + $cur_host.DNSDomain)

$known_host_ip = $cur_host.IPAddress[0]
$mask_ip = $cur_host.IPSubnet[0]

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
    $This_IP=((Get-NetIPConfiguration).IPv4Address).IPv4Address
    if ($IP -eq $This_IP) {
      $InterfaceAlias=(Get-NetIPConfiguration).InterfaceAlias
      $This_HWAddr=(Get-NetAdapter | Where-Object{$_.ifAlias -eq $InterfaceAlias}).MACAddress
      #$This_HWAddr=(Get-NetAdapter).MACAddress | Select-Object -First 1
      $HW_Addr=$This_HWAddr
    } else {
      ping -4 -n 1 -w 2000 $IP > $Null 
      $Cmd_Arp_Out=arp -a | Where-Object {$_.Contains("$IP ")}
      if ($Cmd_Arp_Out -ne $NULL) {
        $HW_Addr=$Cmd_Arp_Out.Substring(24,17)
      }
    }
    $HW_Addr
  }#end function Get-MAC

###Write-Output "----------------------OUT---------------------"
###$a = Get-IPrange -ip $known_host_ip -mask $mask_ip 
###Write-Output $a
###Write-Output "----------------------END OUT---------------------"

$mask_ip = "255.255.255.248" ## temp
$Address = Get-IPrange -ip $known_host_ip -mask $mask_ip ## temp

write-host "Distributing addresses around jobs"
$JobAddresses = @{}            
$CurJob = 0            
$CurAddress = 0            
while ($CurAddress -lt $Address.count)            
{            
    $JobAddresses[$CurJob] += @($Address[$CurAddress])            
    $CurAddress++            
    if ($CurJob -eq $Threads -1)            
    {            
        $CurJob = 0            
    }            
    else            
    {            
        $CurJob++            
    }            
}            
            
$Jobs = @()            
foreach ($n in 0 .. ($Threads-1))            
{            
    Write-host "Starting job $n, for addresses $($JobAddresses[$n])"            
    $Jobs += Start-Job -ArgumentList $JobAddresses[$n] -ScriptBlock {            
        $ping = new-object System.Net.NetworkInformation.Ping            
        Foreach ($Ip in $Args)            
        {            
            trap {            
                new-object psobject -Property {            
                    Status = "Error: $_"            
                    Address = $Ip            
                    RoundtripTime = 0            
                }            
                Continue            
            }            
            $ping.send($Ip,10) | select `
                @{name="Status"; expression={$_.Status.ToString()}},             
                @{name = "Address"; expression={$Ip}}, RoundtripTime            
        }            
    }            
}            
         
Write-Output "Waiting for jobs"            
$ReceivedJobs = 0            
while ($ReceivedJobs -le $Jobs.Count)            
{        
    #Write-Host ("ReceivedJobs - " + $ReceivedJobs)
    foreach ($CompletedJob in ($Jobs | where {$_.State -eq "Completed"}))            
    {            
        Receive-Job $CompletedJob | select status, address, roundtriptime            
        $ReceivedJobs ++            
        sleep 1            
    }            
}            
            
Remove-Job $Jobs            
Write-Output "Done."
