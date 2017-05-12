pragma solidity 0.4.11;
import "Events/EventFactory.sol";


contract OutcomeTokenSwap {

    /*
     *  Constants
     */
    uint8 public constant MAKER = 0;
    uint8 public constant TAKER = 1;
    uint8 public constant NONCE = 0;
    uint8 public constant COLLATERAL_TOKEN_COUNT = 1;
    uint8 public constant OUTCOME_TOKEN_COUNT = 2;
    uint8 public constant OUTCOME_TOKEN_INDEX = 3;

    /*
     *  Storage
     */
    EventFactory public eventFactory;
    mapping (bytes32 => uint) public nonces;

    /*
     *  Public functions
     */
    /// @dev Contract constructor sets event factory contract address.
    function OutcomeTokenSwap(address _eventFactory)
        public
    {
        eventFactory = EventFactory(_eventFactory);
    }

    /// @dev Creates categorical event if it does not exist and swaps outcome tokens for collateral tokens.
    /// @param collateralToken Tokens used as collateral in exchange for outcome tokens.
    /// @param oracle Oracle contract used to resolve the event.
    /// @param oracleEventIdentifier Optional identifier to identify a specific oracle event.
    /// @param outcomeCount Number of event outcomes.
    /// @param trade Encoded trade parameters (nonce, token counts and outcome tokens index).
    /// @param traders Encoded trader addresses.
    /// @param v Encoded signature parameters of traders.
    /// @param r Encoded signature parameters of traders.
    /// @param s Encoded signature parameters of traders.
    function swap(
        address collateralToken,
        address oracle,
        bytes32 oracleEventIdentifier,
        uint8 outcomeCount,
        uint[4] trade,
        address[2] traders,
        uint8[2] v,
        bytes32[2] r,
        bytes32[2] s
    )
        public
    {
        bytes32 eventHash = keccak256(collateralToken, oracle, oracleEventIdentifier, outcomeCount);
        CategoricalEvent _event = eventFactory.categoricalEvents(eventHash);
        // Create event if it doesn't exist
        if (address(_event) == 0)
            _event = eventFactory.createCategoricalEvent(collateralToken, oracle, oracleEventIdentifier, outcomeCount);
        settle(_event, trade, traders, v, r, s);
    }

    /// @dev Creates scalar event if it does not exist and swaps outcome tokens for collateral tokens.
    /// @param collateralToken Tokens used as collateral in exchange for outcome tokens.
    /// @param oracle Oracle contract used to resolve the event.
    /// @param oracleEventIdentifier Optional identifier to identify a specific oracle event.
    /// @param lowerBound Lower bound for event outcome.
    /// @param upperBound Lower bound for event outcome.
    /// @param trade Encoded trade parameters (nonce, token counts and outcome tokens index).
    /// @param traders Encoded trader addresses.
    /// @param v Encoded signature parameters of traders.
    /// @param r Encoded signature parameters of traders.
    /// @param s Encoded signature parameters of traders.
    function swap(
        address collateralToken,
        address oracle,
        bytes32 oracleEventIdentifier,
        int lowerBound,
        int upperBound,
        uint[4] trade,
        address[2] traders,
        uint8[2] v,
        bytes32[2] r,
        bytes32[2] s
    )
        public
    {
        bytes32 eventHash = keccak256(collateralToken, oracle, oracleEventIdentifier, lowerBound, upperBound);
        ScalarEvent _event = eventFactory.scalarEvents(eventHash);
        // Create event if it doesn't exist
        if (address(_event) == 0)
            _event = eventFactory.createScalarEvent(collateralToken, oracle, oracleEventIdentifier, lowerBound, upperBound);
        settle(_event, trade, traders, v, r, s);
    }

    /// @dev Swaps two tokens in one transaction.
    /// @param tokens Encoded exchanged tokens.
    /// @param amounts Encoded exchanged amounts.
    /// @param nonce Trade nonce for trading accounts.
    /// @param traders Encoded trader addresses.
    /// @param v Encoded signature parameters of traders.
    /// @param r Encoded signature parameters of traders.
    /// @param s Encoded signature parameters of traders.
    function swap(
        Token[2] tokens,
        uint[2] amounts,
        uint nonce,
        address[2] traders,
        uint8[2] v,
        bytes32[2] r,
        bytes32[2] s
    )
        public
    {
        // Validate nonce
        validateNonce(traders, nonce);
        // Validate signatures
        bytes32 tradeHash = keccak256(tokens, amounts, nonce);
        validateSignatures(tradeHash, traders, v, r, s);
        // Swap tokens
        if (   !tokens[TAKER].transferFrom(traders[TAKER], this, amounts[TAKER])
            || !tokens[MAKER].transferFrom(traders[MAKER], this, amounts[MAKER])
            || !tokens[TAKER].transfer(traders[MAKER], amounts[TAKER])
            || !tokens[MAKER].transfer(traders[TAKER], amounts[MAKER]))
            throw;
    }

    /*
     *  Internal functions
     */
    /// @dev Settles token swap.
    /// @param _event Event object.
    /// @param trade Encoded trade parameters (nonce, token counts and outcome tokens index).
    /// @param traders Encoded trader addresses.
    /// @param v Encoded signature parameters of traders.
    /// @param r Encoded signature parameters of traders.
    /// @param s Encoded signature parameters of traders.
    function settle(
        Event _event,
        uint[4] trade,
        address[2] traders,
        uint8[2] v,
        bytes32[2] r,
        bytes32[2] s
    )
        internal
    {
        // Validate nonces
        validateNonce(traders, trade[NONCE]);
        // Validate signatures
        bytes32 tradeHash = keccak256(trade, _event.getEventHash());
        validateSignatures(tradeHash, traders, v, r, s);
        // Buy outcome tokens
        buyAllOutcomes(_event, trade, traders);
        // Distribute outcome tokens
        distributeOutcomeTokens(_event, trade, traders);
    }

    /// @dev Validates that trade was signed by both parties.
    /// @param traders Encoded trader addresses.
    /// @param nonce Current trade nonce.
    function validateNonce(address[2] traders, uint nonce)
        internal
    {
        // Validate nonce
        bytes32 nonceHash = keccak256(traders[MAKER]) ^ keccak256(traders[TAKER]);
        if (nonce != nonces[nonceHash])
            revert();
        nonces[nonceHash] += 1;
    }

    /// @dev Validates that trade was signed by both parties.
    /// @param tradeHash Hash identifying trade.
    /// @param traders Encoded trader addresses.
    /// @param v Encoded signature parameters of traders.
    /// @param r Encoded signature parameters of traders.
    /// @param s Encoded signature parameters of traders.
    function validateSignatures(bytes32 tradeHash, address[2] traders, uint8[2] v, bytes32[2] r, bytes32[2] s)
        internal
    {
        // Validate signatures
        if (   ecrecover(tradeHash, v[MAKER], r[MAKER], s[MAKER]) != traders[MAKER]
            || ecrecover(tradeHash, v[TAKER], r[TAKER], s[TAKER]) != traders[TAKER])
            revert();
    }

    /// @dev Transfers collateral tokens from maker and taker and buys all outcomes.
    /// @param _event Event object.
    /// @param traders Encoded trader addresses.
    /// @param trade Encoded trade parameters (nonce, token counts and outcome tokens index).
    function buyAllOutcomes(Event _event, uint[4] trade, address[2] traders)
        internal
    {
        // Buy outcome tokens
        if (   !_event.collateralToken().transferFrom(traders[TAKER], this, trade[COLLATERAL_TOKEN_COUNT])
            || !_event.collateralToken().transferFrom(traders[MAKER], this, trade[OUTCOME_TOKEN_COUNT] - trade[COLLATERAL_TOKEN_COUNT])
            || !_event.collateralToken().approve(_event, trade[OUTCOME_TOKEN_COUNT]))
            revert();
        _event.buyAllOutcomes(trade[OUTCOME_TOKEN_COUNT]);
    }

    /// @dev Distribute outcome tokens between maker and taker.
    /// @param _event Event object.
    /// @param traders Encoded trader addresses.
    /// @param trade Encoded trade parameters (nonce, token counts and outcome tokens index).
    function distributeOutcomeTokens(Event _event, uint[4] trade, address[2] traders)
        internal
    {
        // Distribute tokens between maker and taker
        uint8 outcomeCount = _event.getOutcomeCount();
        for (uint8 i=0; i<outcomeCount; i++)
            if (i == trade[OUTCOME_TOKEN_INDEX])
                _event.outcomeTokens(i).transfer(traders[TAKER], trade[OUTCOME_TOKEN_COUNT]);
            else
                _event.outcomeTokens(i).transfer(traders[MAKER], trade[OUTCOME_TOKEN_COUNT]);
    }
}