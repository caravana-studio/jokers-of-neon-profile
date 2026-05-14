# Deploy y Verificacion en Celo Sepolia

Esta guia documenta el flujo para:

- desplegar `JokersOfNeonProfile` en Celo Sepolia
- verificar el contrato por CLI
- verificar el contrato por API compatible con Celoscan/Etherscan V2

La red usada en este proyecto es:

- red: `Celo Sepolia`
- chain id: `11142220`
- RPC: `https://forno.celo-sepolia.celo-testnet.org`

## Prerrequisitos

- `forge` instalado
- wallet con CELO en Celo Sepolia
- API key de Etherscan para verificacion

## Variables de entorno

No pongas claves privadas en comandos hardcodeados ni en archivos del repo.

Este repo hoy usa `evm/.env` con estos nombres:

```bash
export CELO_ADDRESS="TU_DIRECCION"
export CELO_PRIVATE_KEY="TU_PRIVATE_KEY"
export ETHERSCAN_API_KEY="TU_ETHERSCAN_API_KEY"
```

La RPC de Celo Sepolia puede pasarse inline:

```bash
export RPC_URL="https://forno.celo-sepolia.celo-testnet.org"
```

Si queres mantener compatibilidad con comandos genericos de Foundry que esperan `PRIVATE_KEY`, podes mapearla desde el `.env`:

```bash
cd evm
set -a
source .env
set +a

export RPC_URL="https://forno.celo-sepolia.celo-testnet.org"
export PRIVATE_KEY="$CELO_PRIVATE_KEY"
```

## Compilar y testear

```bash
cd evm
forge build
forge test
```

## Sanity checks previos

Confirmar que la key y la address coinciden:

```bash
cd evm
set -a
source .env
set +a

cast wallet address --private-key "$CELO_PRIVATE_KEY"
```

Confirmar saldo en Celo Sepolia:

```bash
cast balance "$CELO_ADDRESS" --rpc-url "https://forno.celo-sepolia.celo-testnet.org"
```

## Deploy del contrato

El contrato no recibe argumentos de constructor.

```bash
cd evm
set -a
source .env
set +a

forge create \
  src/JokersOfNeonProfile.sol:JokersOfNeonProfile \
  --rpc-url "https://forno.celo-sepolia.celo-testnet.org" \
  --private-key "$CELO_PRIVATE_KEY" \
  --broadcast
```

Salida esperada:

- `Deployer: ...`
- `Deployed to: ...`
- `Transaction hash: ...`

## Verificaciones post deploy

### Ver owner

```bash
cast call CONTRACT_ADDRESS "owner()(address)" --rpc-url "$RPC_URL"
```

### Ver bytecode

```bash
cast code CONTRACT_ADDRESS --rpc-url "$RPC_URL"
```

### Ver saldo

```bash
cast balance DEPLOYER_ADDRESS --rpc-url "$RPC_URL"
```

## Verificar con Forge

Este puede funcionar por CLI, pero en Celo Sepolia a veces falla justo despues del deploy con:

```text
Address is not a smart-contract
```

Eso no necesariamente significa que el deploy fallo: suele ser un problema de indexacion del explorer. Si pasa, esperar unos segundos y reintentar. Si sigue fallando, usar el flujo de API V2 de abajo, que es el fallback recomendado.

```bash
cd evm
set -a
source .env
set +a

forge verify-contract \
  CONTRACT_ADDRESS \
  src/JokersOfNeonProfile.sol:JokersOfNeonProfile \
  --chain 11142220 \
  --verifier etherscan \
  --etherscan-api-key "$ETHERSCAN_API_KEY" \
  --compiler-version v0.8.24+commit.e11b9ed9 \
  --watch
```

Si todo sale bien, la salida termina con algo como:

```text
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
```

## Verificar por API V2

Este flujo quedo validado end-to-end para este repo y es el camino mas confiable si el wrapper de Forge falla por indexacion.

### 1. Generar el standard json input

```bash
cd evm

forge verify-contract \
  CONTRACT_ADDRESS \
  src/JokersOfNeonProfile.sol:JokersOfNeonProfile \
  --show-standard-json-input \
  --compiler-version v0.8.24+commit.e11b9ed9 \
  --evm-version cancun \
  > /tmp/jokers_standard_input.json
```

### 2. Enviar la solicitud de verificacion

```bash
cd evm
set -a
source .env
set +a

SOURCE_CODE="$(cat /tmp/jokers_standard_input.json)"

curl --request POST \
  "https://api.etherscan.io/v2/api?chainid=11142220&module=contract&action=verifysourcecode&apikey=${ETHERSCAN_API_KEY}" \
  --data-urlencode "contractaddress=CONTRACT_ADDRESS" \
  --data-urlencode "sourceCode=${SOURCE_CODE}" \
  --data-urlencode "codeformat=solidity-standard-json-input" \
  --data-urlencode "contractname=src/JokersOfNeonProfile.sol:JokersOfNeonProfile" \
  --data-urlencode "compilerversion=v0.8.24+commit.e11b9ed9" \
  --data-urlencode "optimizationUsed=0" \
  --data-urlencode "runs=200" \
  --data-urlencode "constructorArguments=" \
  --data-urlencode "evmVersion=cancun" \
  --data-urlencode "licenseType=3"
```

Respuesta esperada:

```json
{
  "status": "1",
  "message": "OK",
  "result": "GUID_DE_VERIFICACION"
}
```

### 3. Poll de estado

```bash
GUID="GUID_DE_VERIFICACION"

curl \
  "https://api.etherscan.io/v2/api?chainid=11142220&module=contract&action=checkverifystatus&guid=${GUID}&apikey=${ETHERSCAN_API_KEY}"
```

Respuesta esperada:

```json
{
  "status": "1",
  "message": "OK",
  "result": "Pass - Verified"
}
```

Loop util para esperar hasta que salga de cola:

```bash
GUID="GUID_DE_VERIFICACION"

for i in 1 2 3 4 5 6 7 8 9 10; do
  curl -s \
    "https://api.etherscan.io/v2/api?chainid=11142220&module=contract&action=checkverifystatus&guid=${GUID}&apikey=${ETHERSCAN_API_KEY}"
  echo
  sleep 5
done
```

## Confirmar ABI publicada

Cuando la verificacion ya esta publicada, estos endpoints tienen que responder `status: 1`.

### ABI

```bash
curl \
  "https://api.etherscan.io/v2/api?chainid=11142220&module=contract&action=getabi&address=CONTRACT_ADDRESS&apikey=${ETHERSCAN_API_KEY}"
```

### Source code

```bash
curl \
  "https://api.etherscan.io/v2/api?chainid=11142220&module=contract&action=getsourcecode&address=CONTRACT_ADDRESS&apikey=${ETHERSCAN_API_KEY}"
```

## Explorer

Una vez verificado, el explorer deberia mostrar las pestañas:

- `Code`
- `Read Contract`
- `Write Contract`

URL base:

```text
https://sepolia.celoscan.io/address/CONTRACT_ADDRESS#code
```

## Valores usados para este contrato

- contract path: `src/JokersOfNeonProfile.sol:JokersOfNeonProfile`
- compiler: `v0.8.24+commit.e11b9ed9`
- optimization: `0`
- evm version: `cancun`
- license type: `3` (`MIT`)
- constructor args: ninguno

## Troubleshooting

### Missing or unsupported chainid parameter

Usa el endpoint V2 y pasa `chainid=11142220` en la URL.

### Address is not a smart-contract

Si `cast code CONTRACT_ADDRESS --rpc-url "$RPC_URL"` devuelve bytecode pero `forge verify-contract` responde esto, el deploy ya existe y el problema suele ser del indexador del explorer.

Opciones:

- esperar 15 a 30 segundos y reintentar
- usar directamente el flujo `Verificar por API V2`

### Contract source code not verified

Todavia no quedo publicada la verificacion, o hubo mismatch de compilacion.

### Pending in queue

La solicitud fue aceptada. Reintenta con `checkverifystatus` unos segundos despues.

### Bytecode mismatch

Revisar:

- version exacta del compilador
- si hubo optimizer o no
- `evmVersion`
- constructor args
- nombre exacto del contrato en formato `path:ContractName`
