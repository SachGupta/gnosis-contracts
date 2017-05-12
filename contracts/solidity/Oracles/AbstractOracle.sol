pragma solidity 0.4.11;


/// @title Abstract oracle contract - Functions to be implemented by oracles.
contract Oracle {

    function isOutcomeSet(bytes32 eventIdentifier) public constant returns (bool);
    function getOutcome(bytes32 eventIdentifier) public constant returns (int);
}
