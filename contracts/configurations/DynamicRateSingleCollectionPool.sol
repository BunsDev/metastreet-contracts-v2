// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../Pool.sol";
import "../rates/DynamicTargetUtilizationInterestRateModel.sol";
import "../filters/CollectionCollateralFilter.sol";

/**
 * @title Pool Configuration with a Dynamic Target Utilization Interest Rate
 * Model and Collection Collateral Filter
 * @author MetaStreet Labs
 */
contract DynamicRateSingleCollectionPool is
    Pool,
    DynamicTargetUtilizationInterestRateModel,
    CollectionCollateralFilter
{
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
     */
    constructor(
        address delegationRegistry_,
        address[] memory collateralWrappers
    ) Pool(delegationRegistry_, collateralWrappers) {
        /* Disable initialization of implementation contract */
        _initialized = true;
    }

    /**************************************************************************/
    /* Initializer */
    /**************************************************************************/

    function initialize(bytes memory params, address collateralLiquidator_) external {
        require(!_initialized, "Already initialized");

        _initialized = true;

        /* Decode parameters */
        (
            address collateralToken_,
            address currencyToken_,
            uint64 maxLoanDuration_,
            uint256 originationFeeRate_,
            DynamicTargetUtilizationInterestRateModel.Parameters memory rateParameters
        ) = abi.decode(
                params,
                (address, address, uint64, uint256, DynamicTargetUtilizationInterestRateModel.Parameters)
            );

        /* Initialize Pool */
        Pool._initialize(currencyToken_, maxLoanDuration_, originationFeeRate_, collateralLiquidator_);

        /* Initialize Collateral Filter */
        CollectionCollateralFilter._initialize(collateralToken_);

        /* Initialize Interest Rate Model */
        DynamicTargetUtilizationInterestRateModel._initialize(rateParameters);
    }
}