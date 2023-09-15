// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../Pool.sol";
import "../rates/WeightedInterestRateModel.sol";
import "../filters/SetCollectionCollateralFilter.sol";

/**
 * @title Pool Configuration with a Weighted Interest Rate Model and Set Collection
 * Collateral Filter
 * @author MetaStreet Labs
 */
contract WeightedRateSetCollectionPool is Pool, WeightedInterestRateModel, SetCollectionCollateralFilter {
    /**************************************************************************/
    /* State */
    /**************************************************************************/

    /**
     * @notice Initialized boolean
     */
    bool private _initialized;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice Pool constructor
     * @param collateralLiquidator Collateral liquidator
     * @param delegationRegistry Delegation registry contract
     * @param collateralWrappers Collateral wrappers
     * @param parameters WeightedInterestRateModel parameters
     */
    constructor(
        address collateralLiquidator,
        address delegationRegistry,
        address[] memory collateralWrappers,
        WeightedInterestRateModel.Parameters memory parameters
    ) Pool(collateralLiquidator, delegationRegistry, collateralWrappers) WeightedInterestRateModel(parameters) {
        /* Disable initialization of implementation contract */
        _initialized = true;
    }

    /**************************************************************************/
    /* Initializer */
    /**************************************************************************/

    /**
     * @notice Initializer
     * @dev Fee-on-transfer currency tokens are not supported
     * @param params ABI-encoded parameters
     */
    function initialize(bytes memory params) external {
        require(!_initialized, "Already initialized");

        _initialized = true;

        /* Decode parameters */
        (
            address collateralToken_,
            uint256[] memory tokenIds_,
            address currencyToken_,
            uint64[] memory durations_,
            uint64[] memory rates_
        ) = abi.decode(params, (address, uint256[], address, uint64[], uint64[]));

        /* Initialize Collateral Filter */
        SetCollectionCollateralFilter._initialize(collateralToken_, tokenIds_);

        /* Initialize Pool */
        Pool._initialize(currencyToken_, durations_, rates_);
    }

    /**************************************************************************/
    /* Name */
    /**************************************************************************/

    /**
     * @inheritdoc Pool
     */
    function IMPLEMENTATION_NAME() external pure override returns (string memory) {
        return "WeightedRateSetCollectionPool";
    }
}
