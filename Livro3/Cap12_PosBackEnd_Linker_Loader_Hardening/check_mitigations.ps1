param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$Pattern
)

$results = foreach ($file in (gci $Pattern)) {
    $name = $file.BaseName
    
    start $file.FullName -WindowStyle Hidden
    
    while (-not (gps $name -ea 0)) { sleep -m 100 }
    
    $mit = Get-ProcessMitigation -Id (gps $name).Id
    
    [PSCustomObject]@{
        Binary      = $name
        DEP         = $mit.Dep.Enable
        ASLR        = $mit.Aslr.BottomUp
        HighEntropy = $mit.Aslr.HighEntropy
    }
    
    kill -Name $name -Force
}

$results | ft -a