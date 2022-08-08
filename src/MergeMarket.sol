// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./MergeYes.sol";
import "./MergeNo.sol";

error FailedTransfer();
error BeforeMerge();
error NotFinalized();
error BettingPeriodOver();
error AlreadyFinalized();

contract MergeMarket is Ownable {
    uint256 public bettingEnd = 123;
    uint256 public withdrawStart = 456;
    bool public mergeSuccess;
    bool public isFinalized;

    MergeYes public mergeYes;
    MergeNo public mergeNo;

    constructor() {
        mergeYes = new MergeYes();
        mergeNo = new MergeNo();
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
            amountWon = (mergeYes.totalSupply() + mergeNo.totalSupply())
                * mergeYes.balanceOf(msg.sender)
                / mergeYes.totalSupply();
            mergeYes.burn(msg.sender, mergeYes.balanceOf(msg.sender));
        } else {
            amountWon = (mergeYes.totalSupply() + mergeNo.totalSupply())
                * mergeNo.balanceOf(msg.sender)
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
