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

```bash
export RPC_URL="https://forno.celo-sepolia.celo-testnet.org"
export PRIVATE_KEY="TU_PRIVATE_KEY"
export ETHERSCAN_API_KEY="TU_ETHERSCAN_API_KEY"
```

## Compilar y testear

```bash
cd evm
forge build
forge test
```

## Deploy del contrato

El contrato no recibe argumentos de constructor.

```bash
cd evm

forge create \
  src/JokersOfNeonProfile.sol:JokersOfNeonProfile \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY" \
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

Este fue el camino mas simple por CLI.

```bash
cd evm

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

Si queres verificar sin depender del wrapper de Forge, podes usar el endpoint V2.

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
