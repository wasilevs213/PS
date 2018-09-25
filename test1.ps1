$host_name = 'localhost'
$global:known_host_ip
$global:mask_ip

function GetLocalInfo {
    #получить инфу о локальном хосте
    $host_name = 'localhost'
    $cur_host = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=$true -ComputerName $host_name | Select-Object -Property [a-z]* -ExcludeProperty IPX*,WINS*
    $global:known_host_ip = $cur_host.IPAddress[0]
    $global:mask_ip = $cur_host.IPSubnet[0]
    $CustomObject = New-Object PSObject
    $CustomObject | Add-Member -type NoteProperty -name IPAddress -value $cur_host.IPAddress[0]
    $CustomObject | Add-Member -type NoteProperty -name MACAddress -value $cur_host.MACAddress
    $CustomObject | Add-Member -type NoteProperty -name DNSHostName -value $cur_host.DNSHostName
    $CustomObject | Add-Member -type NoteProperty -name IPSubnet -value $cur_host.IPSubnet[0]
    $CustomObject | Add-Member -type NoteProperty -name DefaultIPGateway -value $cur_host.DefaultIPGateway[0]
    $CustomObject | Add-Member -type NoteProperty -name DNSDomain -value $cur_host.DNSDomain
    $CustomObject | Select-Object IPAddress, IPSubnet, MACAddress, DNSHostName, DefaultIPGateway, DNSDomain
#    Write-Host $cur_host.IPAddress[0].gettype().fullname
#    Write-Host $cur_host.IPSubnet[0].gettype().fullname
    
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
    Write-Host ('Domain: ' + $CurObject.DNSDomain)
} # end function OutLocalInfo
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

function ConvertPSObjTo ([object] $set1) {
    foreach($item in $set1) {
        Write-Host $item
    }
}

$LinuxTestStart = @{body="IT WORKS!!!"; name1="Asdf"; value1="Zxxcvb"}
$ObjJSON = ConvertTo-Json20 $LinuxTestStart
Write-Host $ObjJSON

$LocalInfo = GetLocalInfo 
Write-Host $LocalInfo.gettype().fullname


ConvertPSObjTo $LocalInfo