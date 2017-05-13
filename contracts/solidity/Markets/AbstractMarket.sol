pragma solidity 0.4.11;


/// @title Abstract market contract - Functions to be implemented by market contracts.
contract Market {

    function fund(uint _funding) public;
    function close() public;
    function withdrawFees() public returns (uint);
    function buy(uint8 outcomeTokenIndex, uint outcomeTokenCount, uint maxCosts) public returns (uint);
    function sell(uint8 outcomeTokenIndex, uint outcomeTokenCount, uint minProfits) public returns (uint);
    function shortSell(uint8 outcomeTokenIndex, uint outcomeTokenCount, uint minProfits) public returns (uint);
    function calcMarketFee(uint outcomeTokenCosts) public constant returns (uint);
    function getOutcomeTokenCounts() public constant returns (uint[]);
}
