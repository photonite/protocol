pragma solidity ^0.5.0;

import "../../node_modules/@openzeppelin/contracts/ownership/Ownable.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IOffChainAssetValuator.sol";
import "./AtmLike.sol";

import "../../node_modules/chainlink/v0.5/contracts/ChainlinkClient.sol";

contract OffChainAssetValuatorImplV1 is IOffChainAssetValuator, ChainlinkClient, Ownable, AtmLike {

    /// The amount of LINK to be paid per request
    uint private _oraclePayment;

    /// The job ID that's fired on the LINK nodes to fulfill this contract's need for off-chain data
    bytes32 private _collateralValueJobId;

    /// The value of all off-chain collateral, as determined by Chainlink. This number has 18 decimal places of precision.
    uint private _collateralValue;

    /// The timestamp (in Unix seconds) at which this contract's _collateralValue field was last updated.
    uint private _lastUpdatedTimestamp;

    /// The block number at which this contract's _collateralValue field was last updated.
    uint private _lastUpdatedBlockNumber;

    constructor(
        address linkToken,
        uint oraclePayment,
        uint collateralValue,
        bytes32 collateralValueJobId
    ) public {
        setChainlinkToken(linkToken);
        _oraclePayment = oraclePayment;
        _collateralValueJobId = collateralValueJobId;
        _collateralValue = collateralValue;
        _lastUpdatedTimestamp = block.timestamp;
        _lastUpdatedBlockNumber = block.number;
    }

    function getLastUpdatedTimestamp() public view returns (uint) {
        return _lastUpdatedTimestamp;
    }

    function getLastUpdatedBlockNumber() public view returns (uint) {
        return _lastUpdatedBlockNumber;
    }

    function getOffChainAssetsValue() public view returns (uint) {
        return _collateralValue;
    }

    function getOffChainAssetsValueJobId() public view returns (bytes32) {
        return _collateralValueJobId;
    }

    function setCollateralValueJobId(bytes32 collateralValueJobId) public onlyOwner {
        _collateralValueJobId = collateralValueJobId;
    }

    function setOraclePayment(uint oraclePayment) public onlyOwner {
        _oraclePayment = oraclePayment;
    }

    function submitGetOffChainAssetsValueRequest(
        address oracle
    ) public onlyOwner {
        Chainlink.Request memory request = buildChainlinkRequest(
            _collateralValueJobId,
            address(this),
            this.fulfillGetOffChainAssetsValueRequest.selector
        );
        request.add("action", "sumActive");
        sendChainlinkRequestTo(oracle, request, _oraclePayment);
    }

    function fulfillGetOffChainAssetsValueRequest(
        bytes32 requestId,
        uint collateralValue
    ) public recordChainlinkFulfillment(requestId) {
        _collateralValue = collateralValue;
        _lastUpdatedTimestamp = block.timestamp;
        _lastUpdatedBlockNumber = block.number;

        emit AssetsValueUpdated(collateralValue);
    }

}