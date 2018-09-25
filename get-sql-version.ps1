Clear-host
$SQLSERVER="localhost"
$DatabaseName="master"
$user="sqluser"
$pwd="P@ssw0rd"
$SqlString="select @@VERSION"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString ="Data Source=$SQLSERVER;Database=$DatabaseName;Integrated Security=True"
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlConnection.open()
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$SqlCmd.Connection = $SqlConnection
$SqlCmd.CommandText = $SqlString
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
$SqlConnection.Close()

foreach($row in $DataSet.Tables[0].Rows)
{
$aa = $row[0].ToString().Trim()
}
write-host $aa