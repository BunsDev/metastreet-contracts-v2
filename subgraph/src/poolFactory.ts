import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import { ERC721 } from "../generated/PoolFactory/ERC721";

import { CollectionCollateralFilter as CollectionCollateralFilterContract } from "../generated/PoolFactory/CollectionCollateralFilter";
import { Pool as PoolContract } from "../generated/PoolFactory/Pool";
import { PoolCreated as PoolCreatedEvent } from "../generated/PoolFactory/PoolFactory";
import { CollateralToken as CollateralTokenEntity, Pool as PoolEntity } from "../generated/schema";
import { Pool as PoolTemplate } from "../generated/templates";

export function handlePoolCreated(event: PoolCreatedEvent): void {
  const poolAddress = event.params.pool;
  const poolId = poolAddress.toHexString();
  const poolContract = PoolContract.bind(poolAddress);
  const collectionCollateralFilterContract = CollectionCollateralFilterContract.bind(poolAddress);
  const collateralTokenAddress = collectionCollateralFilterContract.collateralToken();
  const collateralTokenId = collateralTokenAddress.toHexString();

  /**************************************************************************/
  /* Create Pool entity*/
  /**************************************************************************/
  const poolEntity = new PoolEntity(poolId);
  // Properties
  poolEntity.deploymentHash = event.params.deploymentHash;
  poolEntity.collateralToken = collateralTokenId;
  poolEntity.collateralWrappers = poolContract.collateralWrappers().map<Bytes>((x) => x);
  poolEntity.currencyToken = poolContract.currencyToken();
  poolEntity.durations = poolContract.durations();
  poolEntity.rates = poolContract.rates();
  poolEntity.adminFeeRate = poolContract.adminFeeRate();
  poolEntity.collateralLiquidator = poolContract.collateralLiquidator();
  poolEntity.delegationRegistry = poolContract.delegationRegistry();
  // Derived properties
  poolEntity.maxBorrow = BigInt.zero();
  poolEntity.maxLoanDuration = poolEntity.durations[poolEntity.durations.length - 1];
  // State
  poolEntity.adminFeeBalance = BigInt.zero();
  // Statistics
  poolEntity.totalValueLocked = BigInt.zero();
  poolEntity.totalValueAvailable = BigInt.zero();
  poolEntity.totalValueUsed = BigInt.zero();
  poolEntity.loansOriginated = BigInt.zero();
  poolEntity.loansActive = BigInt.zero();
  poolEntity.loansRepaid = BigInt.zero();
  poolEntity.loansLiquidated = BigInt.zero();
  poolEntity.loansCollateralLiquidated = BigInt.zero();

  poolEntity.save();

  /**************************************************************************/
  /* Create or update CollateralToken entity*/
  /**************************************************************************/
  let collateralTokenEntity = CollateralTokenEntity.load(collateralTokenId);
  if (collateralTokenEntity) {
    /* Update collateral token entity if it exists */
    const poolIds = collateralTokenEntity.poolIds;
    poolIds.push(poolId);
    collateralTokenEntity.poolIds = poolIds;
    if (collateralTokenEntity.maxLoanDuration < poolEntity.maxLoanDuration) {
      collateralTokenEntity.maxLoanDuration = poolEntity.maxLoanDuration;
    }
  } else {
    /* Create collateral token entity if it doesn't exists */
    collateralTokenEntity = new CollateralTokenEntity(collateralTokenId);
    collateralTokenEntity.poolIds = [poolId];
    collateralTokenEntity.totalValueLocked = BigInt.zero();
    collateralTokenEntity.totalValueUsed = BigInt.zero();
    collateralTokenEntity.maxBorrow = BigInt.zero();
    collateralTokenEntity.maxLoanDuration = poolEntity.maxLoanDuration;
    const erc721Contract = ERC721.bind(collateralTokenAddress);
    const tokenName = erc721Contract.try_name();
    if (tokenName.reverted) collateralTokenEntity.name = "Unnamed Token";
    else collateralTokenEntity.name = tokenName.value;
  }
  collateralTokenEntity.save();

  /**************************************************************************/
  /* Create Pool data source*/
  /**************************************************************************/
  PoolTemplate.create(event.params.pool);
}
