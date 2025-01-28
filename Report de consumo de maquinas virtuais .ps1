#Report de consumo de maquinas virtuais aplicavel apenas para Hyper-V 
#28/01/2024
#mmiranda@penso.com.br
#
#
#
#
#


#Infelizmente o Hyper-v não exibe de forma simple o consumo de CPU seja em GHZ ou porcentagem, para fazer isso é necessario habilitar a coleta via Measure-VM e para isso
#é necessario habilitar o contador de performance do windows para as vms que deseja coletar as infomaçoes de consumo. Mais sobre isso abaixo.
#https://learn.microsoft.com/en-us/powershell/module/hyper-v/measure-vm?view=windowsserver2025-ps 
#https://www.veeam.com/blog/hyper-v-resource-metering-practical-examples.html

#Aqui vamos veficar se alguma maquina ja possui o Meansure hablitado para ela e ja habilitar nas VMs

Write-Host "Passo 1, verificar se as VMs possuem Meter habilitado"  -ForegroundColor Cyan
# Coleta se VM ja possui a coleta habilitada 
$originalStatus = Get-VM | Select-Object Name, ResourceMeteringEnabled
$originalStatus | Format-Table -AutoSize

# Habilitar o VMResourceMetering para todas as VMs
Get-VM | ForEach-Object { Enable-VMResourceMetering -VMName $_.Name }

Write-Host "Inicio do Report"  -ForegroundColor Cyan
#inicio da coleta 

# Abre array para coletar todas as infos 
$result = @()

# Obter a lista de todas as VMs
$vms = Get-VM

#Passar por todas as VMs rodando o mesmo comando
foreach ($vm in $vms) {
    # Nome da VM
    $vmName = $vm.Name

    # Estado da VM
    $vmState = $vm.State

    # Memória alocada (RAM em GB)
    $memoryAllocated = $vm.MemoryAssigned / 1GB

    # Memória em uso (RAM em GB) - só funciona para VMs ligadas
    $memoryUsed = if ($vmState -eq 'Running') { 
        (Get-VM -Name $vmName).MemoryDemand / 1GB 
    } else { 
        0 
    }

    # CPU alocada (vCPU)
    $cpuAllocated = $vm.ProcessorCount

    # Uso de CPU (em MHz) usando Measure-VM (O Measure só exibe em MHz)
    $cpuMetrics = Measure-VM -VM $vm
    $cpuUsage = $cpuMetrics.AvgCPU

    # Converte o valor de CPU em MHz para GHz
    $cpuGHz = $cpuUsage / 1000

    # Discos virtuais conectados à VM
    $hardDrives = Get-VMHardDiskDrive -VMName $vmName

    # Disco alocado em GB (Para ligar uma VM o Hyper-v tira um Snapshot - necessario localizar todos os VHD e Avhds para par somar)
    $diskAllocated = 0
    foreach ($disk in $hardDrives) {
        $diskAllocated += (Get-VHD -Path $disk.Path).Size / 1GB
    }

    # Report do total de recursos 
    $result += [PSCustomObject]@{
        Nome             = $vmName
        Estado           = $vmState
        MemoriaAlocadaGB = "{0:N2}" -f $memoryAllocated
        MemoriaUsadaGB   = "{0:N2}" -f $memoryUsed
        CPUAlocada       = $cpuAllocated
        CPUUsageGHz      = "{0:N2} GHz" -f $cpuGHz
        DiscoAlocadoGB   = "{0:N2}" -f $diskAllocated
    }
}

# Exibir as informações como tabela
$result | Format-Table -AutoSize

#### Fim da coleta 
Write-Host "Passo 2, Inicio do rollbackup para status da coleta"  -ForegroundColor Cyan

# 4. Restaurar o status original de VMResourceMetering
foreach ($vm in $originalStatus) {
    if ($vm.ResourceMeteringEnabled) {
        Enable-VMResourceMetering -VMName $vm.Name
    } else {
        Disable-VMResourceMetering -VMName $vm.Name
    }
}

# Exibir o status final após a restauração (opcional)
Get-VM | Select Name, ResourceMeteringEnabled | Format-Table -AutoSize

Write-Host "Passo 3, Export do resultado em CSV para o seu DESKTOP"  -ForegroundColor Cyan

$dir = [Environment]::GetFolderPath("Desktop")
$dir_final = $dir + "\REPORT_MAQUINAS_VIRTUAIS.csv"
$result |  Export-Csv -Path $dir_final -NoTypeInformation

Write-Host "Arquivo exportado para" $dir_final -ForegroundColor Magenta