pragma solidity 0.4.11;


/// @title Abstract oracle contract - Functions to be implemented by oracles.
contract Oracle {

    event EventRegistration(address indexed creator, bytes32 indexed eventIdentifier);
    event EventResolution(bytes32 indexed eventIdentifier, int outcome);

    function isOutcomeSet(bytes32 eventIdentifier) constant returns (bool isSet);
    function getOutcome(bytes32 eventIdentifier) constant returns (int outcome);
}
