pragma solidity 0.4.11;
import "Events/CategoricalEvent.sol";
import "Events/ScalarEvent.sol";


/// @title Event factory contract - Allows create categorical and scalar events.
/// @author Stefan George - <stefan@gnosis.pm>
contract EventFactory {

    /*
     *  Events
     */
    event CategoricalEventCreation(address indexed creator, bytes32 indexed eventHash, address indexed eventContract);
    event ScalarEventCreation(address indexed creator, bytes32 indexed eventHash, address indexed eventContract);

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
    /// @return Returns event contract.
    function createCategoricalEvent(
        address collateralToken,
        address oracle,
        bytes32 oracleEventIdentifier,
        uint outcomeCount
    )
        public
        returns (CategoricalEvent eventContract)
    {
        bytes32 eventHash = keccak256(collateralToken, oracle, oracleEventIdentifier, outcomeCount);
        if (address(categoricalEvents[eventHash]) != 0)
            // Event does exist
            throw;
        eventContract = new CategoricalEvent(
            collateralToken,
            oracle,
            oracleEventIdentifier,
            outcomeCount
        );
        categoricalEvents[eventHash] = eventContract;
        CategoricalEventCreation(msg.sender, eventHash, eventContract);
        return eventContract;
    }

    /// @dev Creates a new scalar event and adds it to the event mapping.
    /// @param collateralToken Tokens used as collateral in exchange for outcome tokens.
    /// @param oracle Oracle contract used to resolve the event.
    /// @param oracleEventIdentifier Optional identifier to identify a specific oracle event.
    /// @param outcomeCount Number of event outcomes.
    /// @param lowerBound Lower bound for event outcome.
    /// @param upperBound Lower bound for event outcome.
    /// @return Returns event contract.
    function createScalarEvent(
        address collateralToken,
        address oracle,
        bytes32 oracleEventIdentifier,
        uint outcomeCount,
        int lowerBound,
        int upperBound
    )
        public
        returns (ScalarEvent eventContract)
    {
        bytes32 eventHash = keccak256(collateralToken, oracle, oracleEventIdentifier, outcomeCount, lowerBound, upperBound);
        if (address(scalarEvents[eventHash]) != 0)
            // Event does exist already
            throw;
        eventContract = new ScalarEvent(
            collateralToken,
            oracle,
            oracleEventIdentifier,
            outcomeCount,
            lowerBound,
            upperBound
        );
        scalarEvents[eventHash] = eventContract;
        ScalarEventCreation(msg.sender, eventHash, eventContract);
        return eventContract;
    }
}
