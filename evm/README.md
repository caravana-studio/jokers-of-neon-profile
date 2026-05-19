# Jokers of Neon EVM

Version reducida en Solidity del storage que hoy vive repartido entre `profile_system.cairo`, `progression_system.cairo` y el `store` de Dojo.

## Qué incluye

- Un solo contrato: `JokersOfNeonProfile.sol`
- `setGameData` / `getGameData(gameId)`
- `setRoundData` / `getRoundData(gameId, roundId)` / `getRoundsByGameId(gameId)`
- `syncProgression` / `getProgression(player)`
- `getGamesByIdRange(minGameId, maxGameId)` para armar leaderboard en frontend
- Control de acceso estándar con `Ownable` de OpenZeppelin

## Cambios de lógica de Cairo a Solidity

- En Cairo + Dojo, `#[key]` define automáticamente cómo se persiste cada modelo en el `world`. En Solidity hay que modelar esas keys a mano con `mapping`.
- `GameData` se indexa por `gameId`, porque es la key real del modelo. En el `store.cairo` actual el getter recibe `address`, pero el struct tiene `id` como key; para EVM conviene corregir esa ambigüedad y usar `gameId` explícito.
- `RoundData` tiene key compuesta (`gameId`, `roundId`), por eso se modeló como `mapping(uint32 => mapping(uint32 => RoundData))`.
- Solidity no puede enumerar mappings. Para poder listar rounds por `gameId`, el contrato guarda `maxRoundIdByGame` y hace un scan acotado.
- `getGamesByIdRange` también hace un scan inclusivo entre `minGameId` y `maxGameId`. Sirve para leaderboard si el rango es razonable; no mantiene un ranking ordenado on-chain.
- `syncProgression` mantiene exactamente la semántica de Cairo: solo conserva el mejor `tier`, `totalRuns`, `maxLevel` y `maxRound`.
- Los setters quedaron protegidos con `onlyOwner`, reemplazando el esquema previo de `operators`.

## Compilar y testear

```bash
cd evm
forge test
```
