#
#

$LinuxTestStart = @{body="IT WORKS!!!"}
function ConvertTo-Json20([object] $item){
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    return $ps_js.Serialize($item) }
    
$url = "http://webserverIPaddresshere:5000/posts/"

     $body = ConvertTo-Json20 $LinuxTestStart 
    
$request = [System.Net.WebRequest]::Create($url)
$request.ContentType = "application/json"
$request.Method = "POST"
try
{
    $requestStream = $request.GetRequestStream()
    $requestWriter = New-Object System.IO.StreamWriter($requestStream)
    $streamWriter.Write($body)
}
finally
{
    if ($null -ne $streamWriter) { $streamWriter.Dispose() }
    if ($null -ne $requestStream) { $requestStream.Dispose() }
}
$res = $request.GetResponse() 
