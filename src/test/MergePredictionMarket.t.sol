// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../MergePredictionMarket.sol";

interface CheatCodes {
  function prank(address) external;
  function expectRevert(bytes4) external;
  function expectRevert(bytes memory) external;
  function warp(uint256) external;
}

contract MergePredictionMarketTest is Test {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    MergePredictionMarket mergePredictionMarket;

    function setUp() public {
      mergePredictionMarket = new MergePredictionMarket();
    }

}
