// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract ERC20Token is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    function mint(address _account, uint256 _amount) external onlyOwner {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlyOwner {
        _burn(_account, _amount);
    }
}