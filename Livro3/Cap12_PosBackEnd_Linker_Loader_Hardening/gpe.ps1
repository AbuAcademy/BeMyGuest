function gpe($files) {
    $list = foreach($f in $files) {
        if($f -match '[*?]') { gci $f -File | select -exp FullName }
        else { try { (rvpa $f -err 0).Path } catch {} }
    }
    foreach($f in $list) {
        try {
            $b = [IO.File]::ReadAllBytes($f)
            $d = [BitConverter]::ToUInt16($b,
                 [BitConverter]::ToInt32($b, 0x3C) + 0x5E)
            [PSCustomObject]@{
                Binary  = (gi $f).Name
                ASLR    = [bool]($d -band 0x40)
                HighEnt = [bool]($d -band 0x20)
                DEP_NX  = [bool]($d -band 0x100)
            }
        } catch {}
    }
}
gpe $args
