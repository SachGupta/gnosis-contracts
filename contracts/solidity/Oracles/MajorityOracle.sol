pragma solidity 0.4.11;
import "Oracles/AbstractOracle.sol";


/// @title Majority oracle contract - Allows to resolve an event based on multiple oracles with majority vote.
/// @author Stefan George - <stefan@gnosis.pm>
contract MajorityOracle is Oracle {

    /*
     *  Storage
     */
    mapping (bytes32 => OracleIdentifier) oracleIdentifiers;

    struct OracleIdentifier {
        address[] oracles;
        bytes32[] eventIdentifiers;
    }

    /*
     *  Public functions
     */
    /// @dev Allows to registers oracles for a majority vote.
    /// @param oracles List of oracles taking part in the majority vote.
    /// @param eventIdentifiers List of event identifiers for each oracle.
    /// @return Returns event identifier.
    function registerEvent(address[] oracles, bytes32[] eventIdentifiers)
        public
        returns (bytes32 eventIdentifier)
    {
        if (oracles.length != eventIdentifiers.length)
            // Data is invalid
            revert();
        for (uint i=0; i<oracles.length; i++)
            if (oracles[i] == 0)
                revert();
        eventIdentifier = keccak256(oracles, eventIdentifiers);
        oracleIdentifiers[eventIdentifier] = OracleIdentifier({
            oracles: oracles,
            eventIdentifiers: eventIdentifiers
        });
    }

    /// @dev Allows to registers oracles for a majority vote.
    /// @param eventIdentifier Event identifier.
    /// @return Returns if outcome is set.
    /// @return Returns outcome.
    function getStatusAndOutcome(bytes32 eventIdentifier)
        public
        returns (bool outcomeSet, int outcome)
    {
        OracleIdentifier memory oracleIdentifier = oracleIdentifiers[eventIdentifier];
        address[] memory oracles = oracleIdentifier.oracles;
        bytes32[] memory eventIdentifiers = oracleIdentifier.eventIdentifiers;
        uint i;
        int[] memory outcomes = new int[](oracles.length);
        uint[] memory validations = new uint[](oracles.length);
        for (i=0; i<oracles.length; i++) {
            Oracle oracle = Oracle(oracles[i]);
            if (oracle.isOutcomeSet(eventIdentifiers[i])) {
                int _outcome = oracle.getOutcome(eventIdentifiers[i]);
                for (uint j=0; j<=i; j++)
                    if (_outcome == outcomes[j]) {
                        validations[j] += 1;
                        break;
                    }
                    else if (validations[j] == 0) {
                        outcomes[j] = _outcome;
                        validations[j] += 1;
                        break;
                    }
            }
        }
        uint outcomeValidations = 0;
        uint outcomeIndex = 0;
        for (i=0; i<oracles.length; i++)
            if (validations[i] > outcomeValidations) {
                outcomeValidations = validations[i];
                outcomeIndex = i;
            }
        // There is a majority vote
        if (outcomeValidations * 2 > oracles.length) {
            outcomeSet = true;
            outcome = outcomes[outcomeIndex];
        }
    }

    /// @dev Returns if winning outcome is set for given event.
    /// @param eventIdentifier Event identifier.
    /// @return Returns if outcome is set.
    function isOutcomeSet(bytes32 eventIdentifier)
        public
        constant
        returns (bool)
    {
        var (outcomeSet, ) = getStatusAndOutcome(eventIdentifier);
        return outcomeSet;
    }

    /// @dev Returns winning outcome for given event.
    /// @param eventIdentifier Event identifier.
    /// @return Returns outcome.
    function getOutcome(bytes32 eventIdentifier)
        public
        constant
        returns (int)
    {
        var (, winningOutcome) = getStatusAndOutcome(eventIdentifier);
        return winningOutcome;
    }
}
