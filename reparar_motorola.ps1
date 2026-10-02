# Reparo limitado ao sistema do Motorola XT1922-5, Android 9.
# Use na pasta do pacote ALJETER PPPS29.55-35-18-7 ja extraido.
# Nao executa restauracao de fabrica, desbloqueio ou comandos erase.
# Nao grava userdata, metadados, tabela de particoes ou bootloader.
# Uma gravacao em um aparelho defeituoso sempre envolve risco.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$firmwareDir = $PSScriptRoot
$firmwareEsperado = 'PPPS29.55-35-18-7'
$xmlPath = Join-Path $firmwareDir 'flashfile.xml'
$fastbootPath = Join-Path $firmwareDir 'fastboot.exe'
if (-not (Test-Path -LiteralPath $fastbootPath -PathType Leaf)) {
    $fastbootPath = Join-Path $firmwareDir 'mfastboot.exe'
}
if (-not (Test-Path -LiteralPath $fastbootPath -PathType Leaf)) {
    throw 'Coloque este arquivo na pasta que contem fastboot.exe ou mfastboot.exe e o firmware extraido.'
}
if (-not (Test-Path -LiteralPath $xmlPath -PathType Leaf)) {
    throw 'flashfile.xml ausente. Extraia o pacote completo antes de executar o reparo.'
}

[xml]$manifesto = Get-Content -LiteralPath $xmlPath -Raw
if ($manifesto.OuterXml -notmatch [regex]::Escape($firmwareEsperado)) {
    throw 'Este script exige o mesmo firmware PPPS29.55-35-18-7 registrado na conversa.'
}
$identificacao = @(Get-ChildItem -LiteralPath $firmwareDir -File -Filter '*XT1922-5*info.txt' |
    Where-Object { $_.Name -like ('*' + $firmwareEsperado + '*') })
if ($identificacao.Count -ne 1) {
    throw 'O pacote deve conter seu arquivo info.txt que identifica XT1922-5 e PPPS29.55-35-18-7.'
}

# A ordem das imagens vem do XML do pacote, inclusive todos os sparsechunks.
# Uma lista fechada evita executar qualquer outro passo existente no XML.
$particoesPermitidas = @('system', 'vendor', 'oem')
$plano = @()
foreach ($passo in $manifesto.SelectNodes('//step')) {
    $operacao = $passo.GetAttribute('operation').ToLowerInvariant()
    $particao = $passo.GetAttribute('partition').ToLowerInvariant()
    if ($operacao -ne 'flash' -or $particoesPermitidas -notcontains $particao) {
        continue
    }
    $arquivo = $passo.GetAttribute('filename')
    $padraoArquivo = '^' + [regex]::Escape($particao) + '\.img(?:_sparsechunk\.\d+)?$'
    if ($arquivo -notmatch $padraoArquivo) {
        throw ('Nome de imagem inesperado para ' + $particao + '. Nenhuma gravacao foi iniciada.')
    }
    $imagemPath = Join-Path $firmwareDir $arquivo
    if (-not (Test-Path -LiteralPath $imagemPath -PathType Leaf)) {
        throw ('Falta ' + $arquivo + '. Extraia o pacote completo. Nenhuma gravacao foi iniciada.')
    }
    if ((Get-Item -LiteralPath $imagemPath).Length -eq 0) {
        throw ('A imagem ' + $arquivo + ' esta vazia. Nenhuma gravacao foi iniciada.')
    }
    $plano += [pscustomobject]@{ Particao = $particao; Arquivo = $arquivo; Caminho = $imagemPath }
}
if (@($plano | Where-Object { $_.Particao -eq 'system' }).Count -eq 0) {
    throw 'O XML nao contem as imagens do sistema. Nenhuma gravacao foi iniciada.'
}

function Invoke-FastbootSeguro {
    param([string[]]$Argumentos)
    $preferenciaAnterior = $ErrorActionPreference
    # fastboot escreve tambem mensagens normais em stderr no Windows PowerShell.
    $ErrorActionPreference = 'Continue'
    try {
        $linhas = @(& $script:fastbootPath @Argumentos 2>&1)
        $codigo = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $preferenciaAnterior
    }
    $texto = ($linhas | ForEach-Object { $_.ToString() }) -join "`n"
    foreach ($linha in $linhas) { Write-Host $linha.ToString() }
    if ($codigo -ne 0 -or $texto -match '(?im)^\s*(FAILED|FAIL|error)\b') {
        throw 'O aparelho recusou ou falhou no comando. Reparo interrompido. Nao desbloqueie nem formate o aparelho.'
    }
    return $texto
}

# Apenas identificacao breve antes da primeira gravacao, sem hashes.
$dispositivos = Invoke-FastbootSeguro -Argumentos @('devices')
if ([regex]::Matches($dispositivos, '(?m)^\S+\s+fastboot\s*$').Count -ne 1) {
    throw 'Conecte somente este Motorola, ja na tela de fastboot. Nenhuma gravacao foi iniciada.'
}
$produto = Invoke-FastbootSeguro -Argumentos @('getvar', 'product')
if ($produto -notmatch '(?im)product\s*:\s*(aljeter|jeter)\b') {
    throw 'O aparelho conectado nao foi identificado como jeter ou aljeter. Nenhuma gravacao foi iniciada.'
}
$modelo = Invoke-FastbootSeguro -Argumentos @('getvar', 'sku')
if ($modelo -notmatch '(?im)sku\s*:\s*XT1922-5\b') {
    throw 'O aparelho conectado nao foi identificado como XT1922-5. Nenhuma gravacao foi iniciada.'
}

Write-Host 'Iniciando a reinstalacao das particoes do sistema com o firmware da mesma versao.'
Write-Host 'Mantenha o cabo conectado. O script para na primeira falha e nao executa um reset.'
foreach ($item in $plano) {
    Write-Host ('Gravando ' + $item.Particao + ' com ' + $item.Arquivo)
    [void](Invoke-FastbootSeguro -Argumentos @('flash', $item.Particao, $item.Caminho))
}
[void](Invoke-FastbootSeguro -Argumentos @('reboot'))
Write-Host 'Gravacao concluida. Aguarde a inicializacao. Se iniciar, desbloqueie a tela e copie seus arquivos imediatamente.'
Write-Host 'Se continuar em loop, este reparo nao resolveu. A proxima etapa e avaliar a placa original preservando os dados.'
