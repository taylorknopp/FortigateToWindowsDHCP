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
  #Write-Output $dhcpLines
  $indexOfStartReservationsSection = 0

  [string[]]$dnsServers = @()
  $defaultGatway = @()
  $netMask = @()
  $scopeName = @()
  $startIP = @()
  $endIP = @()
  

  foreach($line in $dhcpLines)
  {
        #find DG
        if($line.Contains("set default-gateway"))
        {
            $defaultGatway = $line.Trim();
        }
        #find netnask
        if($line.Contains("set netmask"))
        {
            $netMask = $line.Trim();
        }
        #find start ip range
        if($line.Contains("set start-ip"))
        {
            $startIP = $line.Trim();
        }
        #find end ip rnage
        if($line.Contains("set end-ip"))
        {
            $endIP = $line.Trim();
        }
        #find scope name
        if($line.Contains(" set interface"))
        {
            $scopeName = $line.Trim();
        }
        #find dns
        if($line.Contains("set dns-server"))
        {
            $dnsServers += $line.Trim();
        }
  }

 $scopeName = $scopeName.Substring(15,$scopeName.Length - 16)
 $startIP = $startIP.Substring(13,$startIP.Length - 13)
 $endIP = $endIP.Substring(11,$endIP.Length - 11)
 $netMask = $netMask.Substring(12,$netmask.Length - 12)
 $defaultGatway = $defaultGatway.Substring(20,$defaultGatway.Length - 20)
 for($i =0; $i -le $dnsServers.Length - 1; $i++)
 {
    $dnsServers[$i] = $dnsServers[$i].Substring(16,$dnsServers[$i].Length - 16)
 }

  Write-Output $scopeName
  Write-Output $startIP
  Write-Output $endIP
  Write-Output $netMask
  Write-Output $defaultGatway
  Write-Output $dnsServers

  foreach($line in $dhcpLines)
  {

    if($line.Contains("reserved-address"))
    {
        break
    }
    $indexOfStartReservationsSection++

  }


  [int[]]$startReservationSections = @();
  [int[]]$endReservationSections = @();
  $x= $indexOfStartReservationsSection

  $dhcpReservationLines = $dhcpLines[$indexOfStartReservationsSection..$dhcpLines.Count]
  #Write-Output $dhcpReservationLines
  foreach($line in $dhcpReservationLines)
  {
    if($line.Contains("edit"))
    {
        $startReservationSections += $x
    }
    if($line.Contains("next"))
    {
        $endReservationSections += $x
        
    }
    $x++

  }
 
  Install-WindowsFeature DHCP -IncludeManagementTools
  Add-DhcpServerv4Scope -name $scopeName -StartRange $startIP -EndRange $endIP -SubnetMask $netMask -State Active
  Set-DhcpServerv4OptionValue -Router $defaultGatway
  Set-DhcpServerv4OptionValue -DnsServer $dnsServers -Force
  $scopeID = $startIP.Substring(0,$startIP.Length - $startIP.IndexOf(".")) + 0
  #Write-Output $scopeID
  for($i =0; $i -le $startReservationSections.Length - 1; $i++)
  {
    $resevationAddress = $dhcpLines[$startReservationSections[$i] + 1].Trim()
    $resevationAddress = $resevationAddress.Substring(7)
    $macAddress = $dhcpLines[$startReservationSections[$i] + 2].Trim()
    $macAddress = $macAddress.Substring(8).Replace(":","-")
    $name = $dhcpLines[$startReservationSections[$i] + 3].Trim()
    $name = $name.Substring(17,$name.Length - 18)
    $whatWeAreDoing = "Adding Reservation for " + $name + " @ " + $resevationAddress + " with mac of " + $macAddress
    Write-Output $whatWeAreDoing

    Add-DhcpServerv4Reservation -ScopeId $scopeID -IPAddress $resevationAddress -ClientId $macAddress -Name $name 

  }
 


  #Write-Output $startReservationSections.Count
  #Write-Output $endReservationSections.Count