$FilePath = Read-Host -Prompt "Fortinet DHCP File to load" 

$fileContent = Get-Content -Path $FilePath
$i = 0
$start = 0
$end = 0
ForEach ($line in $fileContent) {

   

    if( $line.Contains("config system dhcp server") )
    {
       
       $start = $i
    }

    if($line.Contains("config firewall address"))
    {
        $end = $i - 1
        break

    }
    $i++
    

  }
  #Write-Output $start
  #Write-Output $end
  #Write-Output $fileContent[$start]
  #Write-Output $fileContent[$end]
  [string[]]$dhcpLines = @()
  $y = 0;
  for($x = $start; $x -le $end; $x++)
  {
      $newLine = $fileContent[$x];
    $dhcpLines += ,$newLine

  }
  Write-Output $dhcpLines
