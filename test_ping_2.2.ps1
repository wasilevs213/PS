#Объявляем параметры и их значения по умолчанию
#param ([string[]]$Servers, [int]$Count=-1, $Timeout=1)
[string[]]$Address1 = $(1..12 | %{"10.124.1.$_"})
#$Count = 1
$Hosts = @{}
$Timeout=1
$Version = 2.2

Function Get-MAC ($IP) {
      $Cmd_Arp_Out=arp -a | Where-Object {$_.Contains("$IP ")}
      if ($Cmd_Arp_Out -ne $NULL) {
        $HW_Addr=$Cmd_Arp_Out.Substring(24,17)
      }
    $HW_Addr
  }#end function Get-MAC

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
}

function OutLocalInfo {
    #получить и вывести инфу о локальном хосте
        $host_name = 'localhost'
        Write-Output "Start scanner, version is $Version."
        Write-Output "Time starting: $(get-date -format F)"
        $cur_host = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=$true -ComputerName $host_name | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS* | select-Object -Property IPAddress, MACAddress, IPSubnet
        $ip_addr_host = $cur_host.IPAddress[0]
        Write-Output "Local system: $host_name"
        Write-Output ('Ip address: ' + $ip_addr_host)
        Write-Output ('MAC address: ' + $cur_host.MACAddress)
        Write-Output ('Subnet mask: ' + $cur_host.IPSubnet[0])
        Write-Output ('Default gateway' + $cur_host.DefaultIPGateway)
        Write-Output ('DNS host name: ' + $cur_host.DNSHostName)
        Write-Output ('Domain: ' + $cur_host.DNSDomain)
}
    
$H = ScanSubNet $Address1 $Timeout

OutLocalInfo
Write-Host "All count: "  $Address1.count
write-host "Accessible hosts: " $H.count

foreach ($Key_1 in $H.Keys) {
    Write-Host($Key_1 + " - " + $H[$Key_1])
}
