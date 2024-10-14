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

import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ReentrancyGuard } from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
/**
 * @title Decentralized Stable Coin
 * @author Thibaud Merieux (implementing Patrick Collins tutorial)
 * Collateral : ETH & BTC
 * Minting: Algorithmic
 * Burn: Algorithmic
 * Peg: USD
 */

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    error DecentralizedStableCoin__MustBeMoreThanZero();
    error DecentralizedStableCoin__BurnAmountExceedsBalance();
    error DecentralizedStableCoin__CannotMintOn0Adress();

    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266) { }

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DecentralizedStableCoin__BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin__CannotMintOn0Adress();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin__MustBeMoreThanZero();
        }
        super._mint(_to, _amount);
        return true;
    }
}
