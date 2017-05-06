/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
pragma solidity 0.4.11;


/// @title Abstract token contract - Functions to be implemented by token contracts.
contract Token {

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function transfer(address to, uint value) returns (bool);
    function transferFrom(address from, address to, uint value) returns (bool);
    function approve(address spender, uint value) returns (bool);
    function balanceOf(address owner) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);
    uint public totalSupply;
}
