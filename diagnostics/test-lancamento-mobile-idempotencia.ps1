param(
  [string]$BaseUrl = "http://127.0.0.1:9000",
  [int]$Empresa = 1,
  [int]$Venda = 0,
  [int]$Produto = 0,
  [int]$Garcom = 0,
  [decimal]$ValorUnitario = 1.00,
  [int]$Repeticoes = 8,
  [string]$Terminal = "QA-MOBILE"
)

$ErrorActionPreference = "Stop"

if ($Venda -le 0) {
  throw "Informe -Venda com uma venda/mesa aberta em status pendente."
}

if ($Produto -le 0) {
  throw "Informe -Produto com um produto valido para lancamento."
}

if ($Repeticoes -lt 2) {
  $Repeticoes = 2
}

$base = $BaseUrl.TrimEnd("/")
$uri = "$base/rpCheff/v1/empresa/$Empresa/venda/$Venda/item/lote"
$mobileLaunchId = "qa-idem-$((Get-Date).ToString('yyyyMMddHHmmss'))-$([Guid]::NewGuid().ToString('N').Substring(0, 8))"

$item = [ordered]@{
  mobileLaunchId = $mobileLaunchId
  idProduto = $Produto
  quantidade = 1
  valorUnitario = $ValorUnitario
  valorTotal = $ValorUnitario
  desconto = 0
  acrescimo = 0
  tamanho = "M"
  vendaPorTamanho = $false
  descricaoTamanho = ""
  observacao = "QA IDEMPOTENCIA MOBILE"
  idMesaVinculada = 0
  idGarcom = $Garcom
  terminalImpressao = $Terminal
  opcionais = @()
}

$body = @($item) | ConvertTo-Json -Depth 8

Write-Host "POST $uri"
Write-Host "mobileLaunchId=$mobileLaunchId"
Write-Host "Enviando uma vez para criar a linha..."
Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json; charset=utf-8" | Out-Null

Write-Host "Reenviando o mesmo payload $Repeticoes vezes em paralelo..."
$jobs = 1..$Repeticoes | ForEach-Object {
  Start-Job -ScriptBlock {
    param($JobUri, $JobBody)
    Invoke-RestMethod -Uri $JobUri -Method Post -Body $JobBody -ContentType "application/json; charset=utf-8" | Out-Null
    "OK"
  } -ArgumentList $uri, $body
}

$results = $jobs | Wait-Job | Receive-Job
$failed = $jobs | Where-Object { $_.State -eq "Failed" }
$jobs | Remove-Job

if ($failed.Count -gt 0) {
  throw "$($failed.Count) reenvio(s) falharam. Verifique o log da API antes de aprovar."
}

Write-Host "Retornos recebidos: $($results.Count)"
Write-Host ""
Write-Host "Valide no banco. O resultado aprovado deve ser qtd=1:"
Write-Host "select id_lancamento_mobile, count(*) as qtd, min(ite_001) as primeiro_item, max(ite_001) as ultimo_item"
Write-Host "from vendaitem"
Write-Host "where emp_001 = $Empresa and ven_001 = $Venda and id_lancamento_mobile = '$mobileLaunchId'"
Write-Host "group by id_lancamento_mobile;"
