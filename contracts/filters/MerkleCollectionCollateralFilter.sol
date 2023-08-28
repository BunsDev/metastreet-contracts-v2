// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../CollateralFilter.sol";

/**
 * @title Merkle Collection Collateral Filter
 * @author MetaStreet Labs
 */
contract MerkleCollectionCollateralFilter is CollateralFilter {
    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Invalid parameters
     */
    error InvalidMerkleParameters();

    /**
     * @notice Invalid context
     */
    error InvalidContext();

    /**************************************************************************/
    /* State */
    /**************************************************************************/

    /**
     * @notice Supported token
     */
    address private _token;

    /**
     * @notice Length of proof (multiple of 32)
     */
    uint32 private _proofLength;

    /**
     * @notice Merkle root
     */
    bytes32 private _root;

    /**
     * @notice Metadata URI
     */
    string private _metadataURI;

    /**************************************************************************/
    /* Initializer */
    /**************************************************************************/

    /**
     * @notice MerkleCollectionCollateralFilter initializer
     */
    function _initialize(address token, bytes32 root, uint32 nodeCount, string memory metadataURI_) internal {
        /* Validate root and node count */
        if (root == bytes32(0) || nodeCount == 0) revert InvalidMerkleParameters();

        _token = token;
        _root = root;
        _proofLength = nodeCount * 32;
        _metadataURI = metadataURI_;
    }

    /**************************************************************************/
    /* Helpers */
    /**************************************************************************/

    /**
     * @notice Helper function that returns merkle proof in bytes32[] shape
     * @param proofData Proof data
     * @return merkleProof Merkle proof
     */
    function _extractProof(bytes calldata proofData) internal pure returns (bytes32[] memory merkleProof) {
        /* Compute node count */
        uint256 nodeCount = proofData.length / 32;

        /* Reduce number of merkle nodes by 1 if last 32 bytes are empty */
        if (bytes32(proofData[proofData.length - 32:]) == bytes32(0)) nodeCount -= 1;

        /* Instantiate merkle proof array */
        merkleProof = new bytes32[](nodeCount);

        /* Populate merkle proof array */
        for (uint256 i; i < nodeCount; i++) {
            /* Set node */
            merkleProof[i] = bytes32(proofData[i * 32:]);
        }
    }

    /**************************************************************************/
    /* Getters */
    /**************************************************************************/

    /**
     * @inheritdoc CollateralFilter
     */
    function COLLATERAL_FILTER_NAME() external pure override returns (string memory) {
        return "MerkleCollectionCollateralFilter";
    }

    /**
     * @inheritdoc CollateralFilter
     */
    function COLLATERAL_FILTER_VERSION() external pure override returns (string memory) {
        return "1.0";
    }

    /**
     * @notice Get collateral token
     * @return Collateral token contract
     */
    function collateralToken() external view override returns (address) {
        return _token;
    }

    /**
     * @notice Get merkle root
     * @return Merkle root
     */
    function merkleRoot() external view returns (bytes32) {
        return _root;
    }

    /**
     * @notice Get metadata URI
     * @return Metadata URI
     */
    function metadataURI() external view returns (string memory) {
        return _metadataURI;
    }

    /**************************************************************************/
    /* Implementation */
    /**************************************************************************/

    /**
     * @inheritdoc CollateralFilter
     */
    function _collateralSupported(
        address token,
        uint256 tokenId,
        uint256 index,
        bytes calldata context
    ) internal view override returns (bool) {
        /* Validate token supported */
        if (token != _token) return false;

        /* Validate context length */
        if (context.length < (index + 1) * _proofLength) revert InvalidContext();

        /* Compute leaf hash */
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(tokenId))));

        return MerkleProof.verify(_extractProof(context[index * _proofLength:(index + 1) * _proofLength]), _root, leaf);
    }
}