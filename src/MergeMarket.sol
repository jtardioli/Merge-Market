// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./ERC20.sol";

error FailedTransfer();
error BeforeMerge();
error NotFinalized();
error BettingPeriodOver();
error AlreadyFinalized();
error NoWinnings();

contract MergeMarket is Ownable {
    uint256 public constant bettingEnd = 123;
    uint256 public constant withdrawStart = 456;
    bool public mergeSuccess;
    bool public isFinalized;

    ERC20Token public mergeYes;
    ERC20Token public mergeNo;

    constructor() {
        mergeYes = new ERC20Token("MergeYes", "MY", 18);
        mergeNo = new ERC20Token("MergeNo", "MN", 18);
    }

    // Make a bet
    function makeBet(bool _merged) external payable {
        if (block.timestamp > bettingEnd) revert BettingPeriodOver();
        if (_merged) {
            mergeYes.mint(msg.sender, msg.value);
            return;
        }
        mergeNo.mint(msg.sender, msg.value);
    }

    function redeemWinnings() external {
        if (!isFinalized) revert NotFinalized();

        uint256 amountWon;

        if (mergeSuccess) {
            uint256 balance = mergeYes.balanceOf(msg.sender);
            if (balance == 0) revert NoWinnings();

            amountWon = (mergeYes.totalSupply() + mergeNo.totalSupply())
                * balance
                / mergeYes.totalSupply();
            mergeYes.burn(msg.sender, mergeYes.balanceOf(msg.sender));
        } else {
            uint256 balance = mergeNo.balanceOf(msg.sender);
            if (balance == 0) revert NoWinnings();

            amountWon = (mergeYes.totalSupply() + mergeNo.totalSupply())
                * balance
                / mergeNo.totalSupply();
            mergeNo.burn(msg.sender, mergeYes.balanceOf(msg.sender));
        }

        (bool success,) = payable(msg.sender).call{value: amountWon}("");
        if (!success) revert FailedTransfer();
    }

    function finalize() external {
        if (block.timestamp < withdrawStart) revert BeforeMerge();
        if (isFinalized) revert AlreadyFinalized();
        isFinalized = true;
        mergeSuccess = block.difficulty < type(uint64).max;
    }
}
