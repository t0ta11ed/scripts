Import-Module MySQLLib
Import-Module VMware.VimAutomation.Core

$conn = New-MySQLConnection -server x.x.x.x -database someDB -user someUser -password UserPw
Invoke-MySQLQuery "DELETE FROM ClusterCPUReady" -connection $conn
$start = get-date
$over10 = New-Object System.Collections.ArrayList

Connect-VIServer -Server somevCenter -User SomeUser -Password 'UserPw' | Out-Null
$esxhosts = @('host1','host2','host3')

$interval = 5
$stat = 'cpu.ready.summation'
$finish = Get-Date
$start = ($finish).AddHours(- $interval)

foreach ($esxhost in $esxhosts) { 

Get-Stat -Entity $esxhost -Stat $stat -Start $start -Finish $finish -Instance "" -MaxSamples 1 -Realtime | select -last 10 |

Group-Object -Property {$_.Entity.Name} | %{

    $_.Group |
%{

            $VM = $_.Entity.Name
            $timeStamp = $_.Timestamp
            $readyMs = $_.Value
            $readyPerc = "{0:P2}" -f ($_.Value/($_.Intervalsecs*1000))
            $esxi = $_.Entity.VMHost
            Invoke-MySQLQuery "INSERT into ClusterCPUReady (Date,VM,ReadyMs,ReadyPerc,EsxHost,Location) VALUES ('$timeStamp','$VM','$readyMs','$readyPerc','$esxi','SomeSite')" -conn $conn
            if ($readyMs -ge "2000") { $over10.Add("$timestamp $VM $readyMs $readyPerc $esxi") | Out-Null }
        } 

    } 
}
 Disconnect-VIServer * -Confirm:$false 
 
$end = get-date
$elapsedTime = New-Timespan -Start $start -End $end

if ($over10) {
    # Send email.
    Send-MailMessage
    }
