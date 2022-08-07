// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../MergeMarket.sol";

contract MergeMarketTest is Test {
    MergeMarket mergeMarket;

    function setUp() public {
        mergeMarket = new MergeMarket();
    }
}
