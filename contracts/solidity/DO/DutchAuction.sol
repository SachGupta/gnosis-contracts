pragma solidity 0.4.4;
import "Tokens/AbstractToken.sol";


/// @title Dutch auction contract - creation of Gnosis tokens.
/// @author Stefan George - <stefan.george@consensys.net>
contract DutchAuction {

    /*
     *  Events
     */
    event BidSubmission(address indexed sender, uint256 amount);

    /*
     *  Constants
     */
    uint constant public TOTAL_TOKENS = 10000000 * 10**18; // 10M
    uint constant public MAX_TOKENS_SOLD = 9000000 * 10**18; // 9M
    uint constant public WAITING_PERIOD = 7 days;

    /*
     *  Storage
     */
    Token public gnosisToken;
    address public wallet;
    address public owner;
    uint public ceiling;
    uint public startPriceFactor;
    uint public startBlock;
    uint public endTime;
    uint public totalReceived;
    uint public finalPrice;
    mapping (address => uint) public bids;
    Stages public stage = Stages.AuctionDeployed;

    /*
     *  Enums
     */
    enum Stages {
        AuctionDeployed,
        AuctionStarted,
        AuctionEnded
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        if (stage != _stage) {
            // Contract not in expected state
            throw;
        }
        _;
    }

    modifier isOwner() {
        if (msg.sender != owner) {
            // Only owner is allowed to proceed
            throw;
        }
        _;
    }

    modifier isWallet() {
        if (msg.sender != wallet) {
            // Only owner is allowed to proceed
            throw;
        }
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && (calcTokenPrice() <= calcStopPrice() || totalReceived == ceiling)) {
            finalizeAuction();
        }
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Contract constructor function sets owner.
    function DutchAuction()
        public
    {
        owner = msg.sender;
        ceiling = 250000 ether;
        startPriceFactor = 4000;
    }

    /// @dev Setup function sets external contracts' addresses.
    /// @param _gnosisToken Gnosis token address.
    /// @param _wallet Gnosis founders address.
    /// @param owners Array of addresses receiving preassigned tokens.
    /// @param tokens Array of preassigned token amounts.
    function setup(address _gnosisToken, address _wallet, address[] owners, uint[] tokens)
        public
        isOwner
    {
        if (wallet != 0 || address(gnosisToken) != 0) {
            // Setup was executed already
            throw;
        }
        wallet = _wallet;
        gnosisToken = Token(_gnosisToken);
        // Assign tokens
        uint totalPreassignedTokens = 0;
        for (uint i=0; i<owners.length; i++) {
            totalPreassignedTokens += tokens[i];
            gnosisToken.transfer(owners[i], tokens[i]);
        }
        if (totalPreassignedTokens != TOTAL_TOKENS - MAX_TOKENS_SOLD) {
            // Preassigned token count doesn't match minimum number of unsold tokens
            throw;
        }
    }

    /// @dev Starts auction and sets startBlock.
    function startAuction()
        public
        isWallet
        atStage(Stages.AuctionDeployed)
    {
        stage = Stages.AuctionStarted;
        startBlock = block.number;
    }

    /// @dev Changes auction ceiling and start price factor before auction is started.
    /// @param _ceiling Updated auction ceiling.
    /// @param _startPriceFactor Updated start price factor.
    function changeCeiling(uint _ceiling, uint _startPriceFactor)
        public
        isWallet
        atStage(Stages.AuctionDeployed)
    {
        ceiling = _ceiling;
        startPriceFactor = _startPriceFactor;
    }

    /// @dev Returns if one week after auction passed.
    /// @return Returns if one week after auction passed.
    function tokenLaunched()
        public
        timedTransitions
        returns (bool)
    {
        return endTime > 0 && block.timestamp > endTime + WAITING_PERIOD;
    }

    /// @dev Returns correct stage, even if a function with timedTransitions modifier has not yet been called yet.
    /// @return Returns current auction stage.
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

    /// @dev Calculates current token price.
    /// @return Returns token price.
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded) {
            return finalPrice;
        }
        return calcTokenPrice();
    }

    /// @dev Allows to send a bid to the auction.
    function bid(address receiver)
        public
        payable
        timedTransitions
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
        if (receiver == 0) {
            receiver = msg.sender;
        }
        amount = msg.value;
        // Prevent that more than 90% of tokens are sold. Only relevant if cap not reached.
        uint maxEtherBasedOnTokenPrice = 9000000 * calcTokenPrice() - totalReceived;
        uint maxEtherBasedOnTotalReceived = ceiling - totalReceived;
        uint maxEther = maxEtherBasedOnTokenPrice;
        if (maxEtherBasedOnTotalReceived < maxEtherBasedOnTokenPrice) {
            maxEther = maxEtherBasedOnTotalReceived;
        }
        // Only invest maximum possible amount.
        if (amount > maxEther) {
            amount = maxEther;
            // Send change back
            if (!receiver.send(msg.value - amount)) {
                // Sending failed
                throw;
            }
        }
        // Forward funding to ether wallet
        if (amount == 0 || !wallet.send(amount)) {
            // No amount sent or sending failed
            throw;
        }
        bids[receiver] += amount;
        totalReceived += amount;
        BidSubmission(receiver, amount);
        // Update the state after investment is done to check if auction is over.
        updateStage();
    }

    /// @dev Claims tokens for bidder after auction.
    function claimTokens(address receiver)
        public
        timedTransitions
        atStage(Stages.AuctionEnded)
    {
        if (receiver == 0) {
            receiver = msg.sender;
        }
        uint tokenCount = bids[receiver] * 10**18 / finalPrice;
        bids[receiver] = 0;
        gnosisToken.transfer(receiver, tokenCount);
    }

    /// @dev Calculates stop price.
    /// @return Returns stop price.
    function calcStopPrice()
        constant
        public
        returns (uint)
    {
        return totalReceived * 10**18 / MAX_TOKENS_SOLD + 1;
    }

    /// @dev Calculates token price.
    /// @return Returns token price.
    function calcTokenPrice()
        constant
        public
        returns (uint)
    {
        return startPriceFactor * 1 ether / (block.number - startBlock + 7500) + 1;
    }

    /*
     *  Private functions
     */
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;
        if (totalReceived == ceiling) {
            finalPrice = calcTokenPrice();
        }
        else {
            finalPrice = calcStopPrice();
        }
        uint soldTokens = totalReceived * 10**18 / finalPrice;
        // Auction contract transfers all unsold tokens to Gnosis inventory multisig
        gnosisToken.transfer(wallet, MAX_TOKENS_SOLD - soldTokens);
        endTime = block.timestamp;
    }
}
