function Get-DatabaseData {
	[CmdletBinding()]
	param (
		[string]$connectionString,
		[string]$query,
		[switch]$isSQLServer
	)
	$connection = New-Object-TypeName System.Data.SqlClient.SqlConnection
	$connection.ConnectionString = $connectionString
	$command = $connection.CreateCommand()
	$command.CommandText = $query
	$adapter = New-Object-TypeName System.Data.SqlClient.SqlDataAdapter $command
	$dataset = New-Object-TypeName System.Data.DataSet
	$adapter.Fill($dataset)
	$dataset.Tables[0]
}

Clear-host
$aa = Get-DatabaseData -verbose -connectionString 'Server=localhost;Database=master;Trusted_Connection=False;User ID=sqluser;Password=P@ssw0rd' -isSQLServer -query "SELECT @@VERSION"
write-host $aa