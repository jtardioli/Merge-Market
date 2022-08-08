// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./MergeYes.sol";
import "./MergeNo.sol";

error FailedTransfer();
error BeforeMerge();
error BettingPeriodOver();
error YouLost();

contract MergeMarket is Ownable {
    uint256 bettingEnd = 123;
    uint256 withdrawStart = 456;
    bool mergeSuccess;

    MergeYes mergeYes;
    MergeNo mergeNo;

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
        if (block.timestamp < withdrawStart) revert BeforeMerge();

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
        mergeSuccess = block.difficulty < type(uint64).max;
    }
}
