# Motorola Android System Repair

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![Android](https://img.shields.io/badge/Android-9-green)
![Device](https://img.shields.io/badge/Motorola-XT1922--5-red)
![License](https://img.shields.io/badge/License-MIT-yellow)

Script em PowerShell desenvolvido para recuperação conservadora do sistema Android em dispositivos Motorola que apresentam bootloop, corrupção do sistema ou falhas durante a inicialização.

O objetivo principal é reinstalar somente componentes essenciais do Android, preservando a partição `userdata` e evitando procedimentos destrutivos sempre que possível.

## Objetivo

O projeto foi criado para situações em que o aparelho ainda é reconhecido pelo Fastboot, mas não consegue concluir corretamente a inicialização do Android.

O script tenta reparar as principais partições relacionadas ao sistema operacional sem executar restauração de fábrica.

A prioridade é permitir uma tentativa de recuperação antes de procedimentos que possam apagar fotos, documentos, aplicativos e demais arquivos pessoais.

## Compatibilidade

A versão atual foi desenvolvida especificamente para o Motorola Moto G6 Play XT1922 5.

Codinome Fastboot

```text
jeter
aljeter
```

Sistema utilizado durante o desenvolvimento

```text
Android 9
```

Firmware utilizado

```text
PPPS29.55-35-18-7
```

O script valida o dispositivo e o firmware antes de iniciar qualquer gravação.

## Partições reparadas

Somente três partições podem ser gravadas pelo script

```text
system
vendor
oem
```

A ordem de gravação é obtida diretamente do arquivo oficial `flashfile.xml` presente no pacote de firmware.

Imagens fragmentadas como `system.img_sparsechunk.0`, `system.img_sparsechunk.1` e demais partes são processadas automaticamente seguindo a sequência definida pelo firmware.

## Preservação dos dados

O script não grava a partição

```text
userdata
```

Também não executa comandos destinados a apagar o armazenamento interno.

As seguintes áreas ficam fora do processo de reparo

```text
userdata
bootloader
tabela de partições
metadados do armazenamento
partições não autorizadas pelo script
```

O script não executa restauração de fábrica.

Também não tenta desbloquear ou bloquear novamente o bootloader.

A preservação de `userdata` reduz significativamente o risco de perda dos arquivos pessoais durante esse procedimento específico, mas não representa garantia absoluta.

Um aparelho com corrupção severa, defeito físico no armazenamento ou falha na placa pode continuar apresentando problemas independentemente das partições modificadas.

## Mecanismos de segurança

Antes da primeira gravação, o script realiza diversas verificações.

Ele confirma a existência do `fastboot.exe` ou `mfastboot.exe`.

Também verifica o `flashfile.xml`, a versão esperada do firmware, o arquivo de identificação do aparelho e a existência das imagens necessárias.

Os arquivos selecionados precisam existir e possuir conteúdo válido.

O script também verifica se existe exatamente um dispositivo conectado em modo Fastboot.

O produto precisa ser identificado como

```text
jeter
```

ou

```text
aljeter
```

O SKU precisa corresponder a

```text
XT1922-5
```

Caso alguma dessas verificações falhe, nenhuma gravação é iniciada.

## Interrupção automática em caso de erro

Cada comando enviado ao Fastboot é monitorado individualmente.

O script verifica o código de saída do processo e também analisa a resposta textual procurando indicadores como

```text
FAILED
FAIL
error
```

Caso alguma falha seja detectada, o processo é interrompido imediatamente.

O script não continua automaticamente para as próximas imagens depois de uma falha identificada.

Também não executa formatação como tentativa automática de correção.

## Requisitos

Windows com PowerShell disponível.

Dispositivo Motorola compatível.

Aparelho capaz de acessar o modo Fastboot.

Cabo USB funcional.

Drivers Motorola corretamente instalados.

Pacote completo do firmware correspondente ao aparelho.

`fastboot.exe` ou `mfastboot.exe`.

Arquivo `flashfile.xml`.

Script `reparar_motorola.ps1`.

## Estrutura esperada

O script deve ficar dentro da mesma pasta onde o firmware foi completamente extraído.

Exemplo

```text
firmware/
│
├── reparar_motorola.ps1
├── fastboot.exe
├── flashfile.xml
├── boot.img
├── bootloader.img
├── oem.img
├── vendor.img
├── system.img_sparsechunk.0
├── system.img_sparsechunk.1
├── system.img_sparsechunk.2
├── system.img_sparsechunk.3
├── ...
└── ALJETER_PPPS29.55-35-18-7_XT1922-5_info.txt
```

A quantidade de arquivos `system.img_sparsechunk` pode variar conforme o pacote utilizado.

## Execução

Coloque o aparelho na tela de Fastboot e conecte ao computador.

Abra o PowerShell dentro da pasta do firmware.

Execute

```powershell
.\reparar_motorola.ps1
```

O script realizará primeiro as verificações de segurança.

Exemplo de identificação

```text
0047633541       fastboot

product: jeter

sku: XT1922-5
```

Quando todas as verificações forem concluídas, o processo de gravação será iniciado.

Exemplo

```text
Iniciando a reinstalacao das particoes do sistema com o firmware da mesma versao.

Mantenha o cabo conectado. O script para na primeira falha e nao executa um reset.

Gravando system com system.img_sparsechunk.0

Sending 'system'
OKAY

Writing 'system'
OKAY
```

O procedimento continua seguindo a ordem determinada pelo `flashfile.xml`.

Após todas as gravações serem concluídas corretamente, o script envia

```text
fastboot reboot
```

## Resultado esperado

Caso o problema esteja relacionado à corrupção de `system`, `vendor` ou `oem`, o Android poderá voltar a inicializar após a reinstalação.

A primeira inicialização pode levar mais tempo que o normal.

Caso o dispositivo consiga iniciar, recomenda se copiar imediatamente todos os arquivos importantes.

O funcionamento temporário do aparelho não elimina a possibilidade de existir uma falha física ou corrupção adicional.

## Bootloop após o reparo

Se o dispositivo continuar em bootloop mesmo depois de todas as imagens terem sido gravadas corretamente, a origem da falha provavelmente está fora das partições tratadas pelo script.

Nesse cenário podem existir problemas em outras áreas do sistema, corrupção relacionada aos dados utilizados durante a inicialização, defeito no armazenamento interno ou falha física na placa.

Como o projeto prioriza a preservação dos dados, ele não tenta corrigir automaticamente essas situações através de formatação.

## Caso utilizado durante o desenvolvimento

No Motorola utilizado durante o desenvolvimento, todas as imagens previstas foram aceitas pelo Fastboot.

As operações de envio e gravação retornaram

```text
OKAY
```

O comando de reinicialização também foi executado normalmente.

Durante algumas gravações foram exibidas mensagens como

```text
is-userspace: not found
is-logical:system: not found
Warning: skip copying system image avb footer due to sparse image.
```

Essas mensagens não impediram a conclusão das respectivas operações.

Mesmo depois da reinstalação de `system`, `vendor` e `oem`, o aparelho utilizado no desenvolvimento continuou apresentando bootloop.

Esse comportamento indicou que, naquele dispositivo específico, a causa não estava limitada às partições substituídas pelo script.

O procedimento ainda cumpriu sua função como tentativa de recuperação conservadora sem apagar `userdata`.

## Limitações

Este projeto não é uma ferramenta universal de recuperação Android.

Ele não corrige defeitos físicos no armazenamento.

Também não consegue reparar automaticamente corrupção existente em partições que foram propositalmente excluídas do procedimento.

A partição `userdata` permanece intacta por projeto.

Caso a causa do bootloop esteja justamente dentro dela, este script não realizará sua formatação ou reconstrução.

Essa limitação é deliberada, pois o objetivo principal é preservar os dados do usuário.

## Aviso

Qualquer operação de gravação em firmware envolve risco.

Utilize somente imagens correspondentes exatamente ao modelo e variante do dispositivo.

Não desconecte o cabo durante uma gravação.

Não desligue o computador durante o processo.

Não utilize este script em dispositivos diferentes do modelo configurado sem revisar previamente todas as validações e partições utilizadas.

O autor não garante recuperação completa do aparelho ou dos dados em casos de falha física, corrupção severa ou utilização de firmware incompatível.

## Licença

Este projeto pode ser distribuído sob a licença MIT.

Consulte o arquivo `LICENSE` do repositório para os termos completos.

## Autor

**Rafael Luiz Carvalho Oliveira**

Desenvolvimento e implementação do script de recuperação do sistema Android para dispositivos Motorola.
