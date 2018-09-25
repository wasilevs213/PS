#Объявляем параметры и их значения по умолчанию
#param ([string[]]$Servers, [int]$Count=-1, $Timeout=1)
[string[]]$Address = $(1..12 | %{"10.124.1.$_"})
#$Count = 1
$Hosts = @{}
$Timeout=1

Function Get-MAC ($IP) {
      $Cmd_Arp_Out=arp -a | Where-Object {$_.Contains("$IP ")}
      if ($Cmd_Arp_Out -ne $NULL) {
        $HW_Addr=$Cmd_Arp_Out.Substring(24,17)
      }
    $HW_Addr
  }#end function Get-MAC


#Создаём объект $pinger, который и будет делать всё самое главное :)
$pinger = New-Object system.net.networkinformation.ping
#Устанавливаем поведение при ошибке - продолжать и не выводить ошибку на экран
$ErrorActionPreference = "SilentlyContinue"
$Time1 = get-date -format F
write-host('Script starting: ' + $Time1)
#Создаём пустой объект
#$Obj = new-object psobject
#Добавляем к нему свойство с именем Time и значением равным текущему времени
#$Obj | add-member -type noteproperty -name "Time" -value (get-date -format "hh:mm:ss")
#Для каждого хоста в массиве $Address...
foreach ($Host_i in $Address)
{
    #Обрабатываем ошибку
    #trap {$Obj | add-member -type noteproperty -name $Host_i -value "Error"}
    #Посылаем ping, и сохраняем результат в переменной $res
    $res = $pinger.Send($Host_i,($Timeout*1000))
    #Если пинг успешен, то
    if ($res.Status -eq "Success")
    {
        #Устанавливаем значение равным времени отклика
        $TimeOut_e = $res.RoundtripTime
        $mac_e = Get-MAC($Host_i)
        $Value = $mac_e
        $Hosts[$Host_i] = $Value
    }
    else
    {
        #Иначе - указываем в значении статус
        $Value = $res.status
    }
    #Добавляем свойство с именем сервера, и значением
    #$Obj | add-member -type noteproperty -name $Host_i -value $Value
}
Write-Host("All count: " + $Address.count)
write-host( "Accessible hosts: " + $Hosts.count )

foreach ($Key_1 in $Hosts.Keys) {
    Write-Host($Key_1 + " - " + $Hosts[$Key_1])
}
