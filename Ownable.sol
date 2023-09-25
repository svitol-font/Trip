// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract Ownable{

    address payable public owner ;

    constructor(address _owner){
        owner = payable(_owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
        owner = payable(newOwner);
        }
    }
}
