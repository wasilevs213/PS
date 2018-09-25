Import-Module "C:\Program Files\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1"
$VMDKpath = "c:\Vm\CentOS\"
$VHDXpath = "c:\Vm\CentOS\"
$FName = "c:\Vm\CentOS\Centos7-disk1.vmdk"
$VMDKfiles = Get-ChildItem "FileSystem::$VMDKpath" -Filter *.vmdk
foreach ($VMDK in $VMDKfiles){
	Write-Host "Converting file: " $VMDK.Name 
	ConvertTo-MVMCVirtualHardDisk -SourceLiteralPath $FName -DestinationLiteralPath $VHDXpath -VHDFormat Vhdx -VHDType DynamicHardDisk
}
