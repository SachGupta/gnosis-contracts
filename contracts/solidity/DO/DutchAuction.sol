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
    uint constant public MAX_TOKENS_SOLD = 9000000 * 10**18; // 9M
    uint constant public WAITING_PERIOD = 7 days;

    /*
     *  Storage
     */
    Token public gnosisToken;
    address public wallet;
    address public owner;
    uint public ceiling;
    uint public priceFactor;
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
        AuctionEnded,
        TradingStarted
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        if (stage != _stage)
            // Contract not in expected state
            throw;
        _;
    }

    modifier isOwner() {
        if (msg.sender != owner)
            // Only owner is allowed to proceed
            throw;
        _;
    }

    modifier isWallet() {
        if (msg.sender != wallet)
            // Only owner is allowed to proceed
            throw;
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stages.AuctionEnded && block.timestamp > endTime + WAITING_PERIOD)
            stage = Stages.TradingStarted;
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
        priceFactor = 4000;
    }

    /// @dev Setup function sets external contracts' addresses.
    /// @param _gnosisToken Gnosis token address.
    /// @param _wallet Gnosis founders address.
    function setup(address _gnosisToken, address _wallet)
        public
        isOwner
    {
        if (wallet != 0 || address(gnosisToken) != 0)
            // Setup was executed already
            throw;
        wallet = _wallet;
        gnosisToken = Token(_gnosisToken);
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
    /// @param _priceFactor Updated start price factor.
    function changeSettings(uint _ceiling, uint _priceFactor)
        public
        isWallet
        atStage(Stages.AuctionDeployed)
    {
        ceiling = _ceiling;
        priceFactor = _priceFactor;
    }

    /// @dev Calculates current token price.
    /// @return Returns token price.
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted)
            return finalPrice;
        return calcTokenPrice();
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

    /// @dev Allows to send a bid to the auction.
    /// @param receiver Bid will be assigned to this address if set.
    function bid(address receiver)
        public
        payable
        timedTransitions
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
        if (receiver == 0)
            receiver = msg.sender;
        amount = msg.value;
        // Prevent that more than 90% of tokens are sold. Only relevant if cap not reached.
        uint maxEther = (MAX_TOKENS_SOLD / 10**18) * calcTokenPrice() - totalReceived;
        uint maxEtherBasedOnTotalReceived = ceiling - totalReceived;
        if (maxEtherBasedOnTotalReceived < maxEther)
            maxEther = maxEtherBasedOnTotalReceived;
        // Only invest maximum possible amount.
        if (amount > maxEther) {
            amount = maxEther;
            // Send change back
            if (!receiver.send(msg.value - amount))
                // Sending failed
                throw;
        }
        // Forward funding to ether wallet
        if (amount == 0 || !wallet.send(amount))
            // No amount sent or sending failed
            throw;
        bids[receiver] += amount;
        totalReceived += amount;
        if (totalReceived == ceiling)
            // Finalize auction if funding goal is reached
            finalizeAuction();
        BidSubmission(receiver, amount);
    }

    /// @dev Claims tokens for bidder after auction.
    /// @param receiver Tokens will be assigned to this address if set.
    function claimTokens(address receiver)
        public
        timedTransitions
        atStage(Stages.TradingStarted)
    {
        if (receiver == 0)
            receiver = msg.sender;
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
        return priceFactor * 1 ether / (block.number - startBlock + 7500) + 1;
    }

    /*
     *  Private functions
     */
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;
        if (totalReceived == ceiling)
            finalPrice = calcTokenPrice();
        else
            finalPrice = calcStopPrice();
        uint soldTokens = totalReceived * 10**18 / finalPrice;
        // Auction contract transfers all unsold tokens to Gnosis inventory multisig
        gnosisToken.transfer(wallet, MAX_TOKENS_SOLD - soldTokens);
        endTime = block.timestamp;
    }
}
