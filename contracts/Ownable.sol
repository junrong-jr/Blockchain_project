// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
  
contract Ownable 
{    
  address private _owner;
  constructor(){
    _owner = msg.sender;
  }
  
  function owner() public view returns(address){
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner(), "Accessible only by the owner !!");
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function transferOwner(address _newOwner) external onlyOwner{
      require(_newOwner != address(0), "Invalid address");
      _owner = _newOwner;
  }
}