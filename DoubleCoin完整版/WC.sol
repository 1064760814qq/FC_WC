// SPDX-License-Identifier:MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20.sol";



contract WC is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    event Withdraw(address user, uint256 amount);


    receive() external payable {}


    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(IERC20 token) public onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function burn(uint256 amount) public virtual {
        super._burn(_msgSender(), amount);
    }


    constructor() ERC20("WC", "WC") {
        _mint(owner(), 10 *10**8 * 10**decimals());
    }

    function BatchTransfer(address[] memory accounts, uint256[] memory amounts)
        public
        onlyOwner
    {
        require(accounts.length == amounts.length,"length is invalid");
        for (uint256 index = 0; index < accounts.length; index++) {
            super._transfer(address(this), accounts[index],amounts[index]);
        }
    }

    function BatchMint(address[] memory accounts, uint256[] memory amounts)
        public
        onlyOwner
    {
        require(accounts.length == amounts.length,"length is invalid");
        for (uint256 index = 0; index < accounts.length; index++) {
            super._mint(accounts[index],amounts[index]);
        }
    }



}