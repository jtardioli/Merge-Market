// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../MergeMarket.sol";

contract MergeMarketTest is Test {
    MergeMarket mergeMarket;
    MergeYes mergeYes;
    MergeNo mergeNo;

    function setUp() public {
        mergeMarket = new MergeMarket();
        mergeYes = mergeMarket.mergeYes();
        mergeNo = mergeMarket.mergeNo();
    }

    function testMakeBet(bool betValue, uint96 amount) public {
        vm.warp(mergeMarket.bettingEnd() - 1);

        if (betValue) {
            mergeMarket.makeBet{value: amount}(true);
            assertEq(mergeYes.balanceOf(address(this)), amount);
        } else {
            mergeMarket.makeBet{value: amount}(false);
            assertEq(mergeNo.balanceOf(address(this)), amount);
        }
    }

    function testCannotBetAfterBettingPeriod(bool betValue, uint96 amount) public {
        vm.warp(mergeMarket.bettingEnd() + 1);

        vm.expectRevert(BettingPeriodOver.selector);
        mergeMarket.makeBet{value: amount}(betValue);
    }

    function testFinalize() public {
        vm.warp(mergeMarket.withdrawStart());

        mergeMarket.finalize();
        assertEq(mergeMarket.isFinalized(), true);
        // Should always return true since block.difficulty is 0 locally
        assertEq(mergeMarket.mergeSuccess(), true);
    }

    function testCannotFinalizeBeforeMerge() public {

    }
}
