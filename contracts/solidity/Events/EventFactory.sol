pragma solidity 0.4.11;
import "Events/CategoricalEvent.sol";
import "Events/ScalarEvent.sol";


contract EventFactory {

    /*
     *  Events
     */
    event CategoricalEventCreation(address indexed creator, bytes32 indexed eventHash, address indexed eventAddress);
    event ScalarEventCreation(address indexed creator, bytes32 indexed eventHash, address indexed eventAddress);

    /*
     *  Storage
     */
    mapping (bytes32 => CategoricalEvent) public categoricalEvents;
    mapping (bytes32 => ScalarEvent) public scalarEvents;

    /*
     *  Public functions
     */
    /// @dev Creates a new categorical event and adds it to the event mapping.
    /// @param collateralToken Tokens used as collateral in exchange for outcome tokens.
    /// @param oracle Oracle contract used to resolve the event.
    /// @param oracleEventIdentifier Optional identifier to identify a specific oracle event.
    /// @param outcomeCount Number of event outcomes.
    function createCategoricalEvent(
        address collateralToken,
        address oracle,
        bytes32 oracleEventIdentifier,
        uint outcomeCount
    )
        public
        returns (CategoricalEvent _event)
    {
        bytes32 eventHash = keccak256(collateralToken, oracle, oracleEventIdentifier, outcomeCount);
        if (address(categoricalEvents[eventHash]) != 0)
            // Event does not exist
            throw;
        _event = new CategoricalEvent(
            collateralToken,
            oracle,
            oracleEventIdentifier,
            outcomeCount
        );
        categoricalEvents[eventHash] = _event;
        CategoricalEventCreation(msg.sender, eventHash, _event);
        return _event;
    }

    /// @dev Creates a new scalar event and adds it to the event mapping.
    /// @param collateralToken Tokens used as collateral in exchange for outcome tokens.
    /// @param oracle Oracle contract used to resolve the event.
    /// @param oracleEventIdentifier Optional identifier to identify a specific oracle event.
    /// @param outcomeCount Number of event outcomes.
    /// @param lowerBound Lower bound for event outcome.
    /// @param upperBound Lower bound for event outcome.
    function createScalarEvent(
        address collateralToken,
        address oracle,
        bytes32 oracleEventIdentifier,
        uint outcomeCount,
        int lowerBound,
        int upperBound
    )
        public
        returns (ScalarEvent _event)
    {
        bytes32 eventHash = keccak256(collateralToken, oracle, oracleEventIdentifier, outcomeCount, lowerBound, upperBound);
        if (address(scalarEvents[eventHash]) != 0)
            // Event does not exist
            throw;
        _event = new ScalarEvent(
            collateralToken,
            oracle,
            oracleEventIdentifier,
            outcomeCount,
            lowerBound,
            upperBound
        );
        scalarEvents[eventHash] = _event;
        ScalarEventCreation(msg.sender, eventHash, _event);
        return _event;
    }
}
