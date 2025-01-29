#Report de consumo de maquinas virtuais aplicavel apenas para Vmware
#28/01/2024
#mmiranda@penso.com.br
#

#Esse report irá buscar todas as maquinas no vcenter e coletar informações de consumo, para isso seŕa necessario logar via powershell no vmware.
#Para isso iremos usar o modulo VMware.PowerCLI, caso nao tenha o mudolo instalado instale ele como o comando abaixo, basra rodar no powershell
#Install-Module VMware.PowerCLI -Scope CurrentUser
#Muito provavelmente voce recebrá erros de certificado em seu powershell, isso ocorre por conta de o vcenter utilizar um ssl auto-assinado para ignorar o erro faça isso
#Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false 

Write-Host "Passo 1, Vamos solicitar o IP e credenciais para conectar no Vcenter, Nao será armazenado nenhuma informação nesse script"  -ForegroundColor Cyan

#Solicitado IP user e senha do Vcenter
Connect-VIServer

# Coletar informações das VMs
$VMs = Get-VM | Sort-Object Name | ForEach-Object {
    $VM = $_
    $VMView = Get-View -Id $VM.Id

    # CPU
    $CPUAlocada = $VM.NumCpu
    $CPUEmUso = ($VMView.Summary.QuickStats.OverallCpuUsage)

    # Memória
    $MemoriaAlocada = $VM.MemoryGB
    $MemoriaEmUso = ($VMView.Summary.QuickStats.GuestMemoryUsage / 1024) # Convertendo MB para GB

    # Disco
    $Discos = Get-HardDisk -VM $VM | Select-Object Name, CapacityGB
    $DiscoAlocado = ($Discos | Measure-Object -Property CapacityGB -Sum).Sum

    # Criar um objeto com os dados
    [PSCustomObject]@{
        Nome            = $VM.Name
        CPU_Alocada     = $CPUAlocada
        CPU_Em_Uso_MHz  = $CPUEmUso
        Memoria_Alocada = "$MemoriaAlocada GB"
        Memoria_Em_Uso  = "$MemoriaEmUso GB"
        Disco_Alocado   = "$DiscoAlocado GB"
        Discos          = $Discos -join "; "
    }
}

# Exibir no console
$VMs

# Desconectar do vCenter
Disconnect-VIServer -Confirm:$false


Write-Host "Passo 3, Export do resultado em CSV para o seu DESKTOP"  -ForegroundColor Cyan

$dir = [Environment]::GetFolderPath("Desktop")
$dir_final = $dir + "\REPORT_MAQUINAS_VIRTUAIS.csv"
$VMs |  Export-Csv -Path $dir_final -NoTypeInformation

Write-Host "Arquivo exportado para" $dir_final -ForegroundColor Magenta
