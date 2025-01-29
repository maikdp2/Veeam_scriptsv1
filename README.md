# Coletores de maquinas virtuais 
## Este coletor foi pensado para embasamento de tamanho e consumo de maquinas virtuais para replicas via VEEAM

Ness post voce encontrará o script para rodar em Vcenters e Hyper-v, ambos deve ser utlizado apartir do powershell

### Requisitos para Hyper-V

- Utilize no minimo o Powerhsell 5.1. Você pode consultar a versão do seu PS com o comando Get-Host
O Powerhell 7 é totalmente suportado pelo script 

https://learn.microsoft.com/pt-br/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5

### Requisitos para Vcenter
- Necessario o modulo VMware.PowerCLI você pode instala-lo utilizando o comando abaixo 
```sh
Install-Module VMware.PowerCLI -Scope CurrentUser
```
- Você pode enfrentar problemas para se conectar ao Vmware por possuir certificados auto assinado, se for o seu caso utilize o comando abaixo para pular a verificação.
```sh
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false 
```
https://www.powershellgallery.com/packages/VMware.PowerCLI/12.7.0.20091289 

Ao fim do Script o report será salvo no desktop do usuario utilizado no Powershell


