// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AggregatorV3Interface } from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import { DecentralizedStableCoin } from "src/DecentralizedStableCoin.sol";

/**
 * @title DSCEngine
 * @dev This contract is the engine of the DSC
 * System designed to make sure 1 TOKEN = 1 USD
 * Collateral : ETH & BTC
 * @author Thibaud Merieux (implementing Patrick Collins tutorial)
 * @notice This contract is very loosely based on DAI system
 */
contract DSGEngine is ReentrancyGuard {
    ////////////////////////////////////////////////////////////////////
    ///////////////////////// ERRORS ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////
    error DSGEngine__MoreThanZeroError();
    error DSGEngine__TokenNotSupported();
    error DSGEngine__AddressCantBeZero();
    error DSGEngine__TransferFailed();
    error DSGEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();

    ////////////////////////////////////////////////////////////////////
    ///////////////////////// STATE VARIABLES //////////////////////////
    ////////////////////////////////////////////////////////////////////
    DecentralizedStableCoin private immutable i_dsc;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256)) private s_collateralsBalances;
    mapping(address user => uint256 ammount) private s_dscBalances;
    address[] private s_collateralTokens;

    ////////////////////////////////////////////////////////////////////
    ///////////////////////// EVENTS ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    ////////////////////////////////////////////////////////////////////
    ///////////////////////// MODIFIERS ////////////////////////////////
    ////////////////////////////////////////////////////////////////////
    modifier moreThanZero(uint256 _value) {
        if (_value <= 0) {
            revert DSGEngine__MoreThanZeroError();
        }
        _;
    }

    modifier isAllowedToken(address _token) {
        if (s_priceFeeds[_token] == address(0)) {
            revert DSGEngine__TokenNotSupported();
        }
        _;
    }

    modifier addressNotZero(address _address) {
        if (_address == address(0)) {
            revert DSGEngine__AddressCantBeZero();
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////////// FUNCTIONS ////////////////////////////////
    ////////////////////////////////////////////////////////////////////
    /**
     * @dev Constructor for the DSCEngine contract.
     * @param tokenAddresses An array of token addresses to be used in the contract.
     * @param priceFeedAddresses An array of corresponding price feed addresses for the tokens.
     * @param dscAddress The address of the Decentralized Stable Coin (DSC) contract.
     */
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address dscAddress
    )
        addressNotZero(dscAddress)
    {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSGEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    ////////////////////////////////////////////////////////////////////
    ///////////////////////// EXTERNAL FUNCTIONS ///////////////////////
    ////////////////////////////////////////////////////////////////////
    /**
     * @notice Deposits a specified amount of collateral for a given token.
     * @dev This function allows users to deposit collateral into the system.
     *      The collateral amount must be greater than zero and the token must be allowed.
     *      Follows CEI Pattern
     * @param tokenCollateralAddress The address of the token to be used as collateral.
     * @param collateralAmmount The amount of the token to be deposited as collateral.
     */
    function depositCollateral(
        address tokenCollateralAddress,
        uint256 collateralAmmount
    )
        external
        moreThanZero(collateralAmmount)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        // Checks in the modifiers
        // Effects
        s_collateralsBalances[msg.sender][tokenCollateralAddress] += collateralAmmount;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, collateralAmmount);
        // Interactionss
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), collateralAmmount);
        if (!success) {
            revert DSGEngine__TransferFailed();
        }
    }

    function redeemCollateralForDSC() external { }

    /**
     * @notice Mints a specified amount of DSC (Decentralized Stable Coin).
     * @param dscAmountToMint The amount of DSC to be minted.
     */
    function mintDSC(uint256 dscAmountToMint) external moreThanZero(dscAmountToMint) nonReentrant {
        s_dscBalances[msg.sender] += dscAmountToMint;
        revertIsHealthFactorIsBroken(msg.sender);
    }

    function burnDSC() external { }

    function liquidate() external { }

    ////////////////////////////////////////////////////////////////////
    ///////////////////////// INTERNAL FUNCTIONS ///////////////////////
    ////////////////////////////////////////////////////////////////////
    function _getTotalCollateralAndDSCValue(address user)
        private
        view
        returns (uint256 totalCollateralValue, uint256 totalDebtValue)
    {
        uint256 totalDSCValue = s_dscBalances[user];
        uint256 totalCollateralValue = 0; //TODO
    }

    /**
     * Returns how close to liquidation a user is. If below 1, the user is insolvent.
     * @param user The address of the user to check.
     */
    function _getHealthFactor(address user) internal view returns (uint256) {
        (uint256 totalCollateralValue, uint256 totalDebtValue) = _getTotalCollateralAndDSCValue(user);
    }

    function revertIsHealthFactorIsBroken(address user) internal { }

    ////////////////////////////////////////////////////////////////////
    ///////////////////////// VIEW & PURE FUNCTIONS ////////////////////
    ////////////////////////////////////////////////////////////////////

    function getAccountCollateralValue(address user) public view returns (uint256) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 ammount = s_collateralsBalances[user][token];
        }
    }

    function getUsdValue(address token, uint256 ammount) public view returns (uint256) {
        address priceFeed = s_priceFeeds[token];
        uint256 price = IPriceFeed(priceFeed).getPrice(); // TODO AGREGATOR PRICE MNUTE 12 de la video
        return price * ammount;
    }
}
