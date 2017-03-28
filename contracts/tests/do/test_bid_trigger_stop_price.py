from ..abstract_test import AbstractTestContract, accounts, keys, TransactionFailed


class TestContract(AbstractTestContract):
    """
    run test with python -m unittest contracts.tests.do.test_bid_trigger_stop_price

    A bid triggers the stop price to be higher than the token price, thus ending the auction instantly.
    Based on test_dao_dutch_auction_stop_price
    """

    BACKER_1 = 1
    BACKER_2 = 2
    BLOCKS_PER_DAY = 5760
    TOTAL_TOKENS = 10000000 * 10**18
    PREASSIGNED_TOKENS = 1000000 * 10**18
    FUNDING_GOAL = 250000 * 10**18
    START_PRICE_FACTOR = 4000

    def __init__(self, *args, **kwargs):
        super(TestContract, self).__init__(*args, **kwargs)
        self.deploy_contracts = [self.gnosis_token_name, self.dutch_auction_name]

    def test(self):
        # Create wallet
        required_accounts = 1
        wa_1 = 1
        constructor_parameters = (
            [accounts[wa_1]],
            required_accounts
        )
        self.multisig_wallet = self.s.abi_contract(
            self.pp.process('Wallets/MultiSigWalletWithDailyLimit.sol',
                            add_dev_code=True,
                            contract_dir=self.contract_dir),
            language='solidity',
            constructor_parameters=constructor_parameters
        )
        self.dutch_auction.setup(self.gnosis_token.address,
                                 self.multisig_wallet.address,
                                 [self.multisig_wallet.address],
                                 [self.PREASSIGNED_TOKENS])
        # Set funding goal
        change_ceiling_data = self.dutch_auction.translator.encode('changeCeiling',
                                                                   [self.FUNDING_GOAL, self.START_PRICE_FACTOR])
        self.multisig_wallet.submitTransaction(self.dutch_auction.address, 0, change_ceiling_data, sender=keys[wa_1])
        # Start auction
        start_auction_data = self.dutch_auction.translator.encode('startAuction', [])
        self.multisig_wallet.submitTransaction(self.dutch_auction.address, 0, start_auction_data, sender=keys[wa_1])
        # Bidder 1 places a bid in the first block after auction starts
        self.assertEqual(self.dutch_auction.calcTokenPrice(), 4000 * 10**18 / 7500 + 1)
        bidder_1 = 0
        value_1 = 100000 * 10**18  # 100k Ether
        self.s.block.set_balance(accounts[bidder_1], value_1*2)
        bid_amount_1 = self.dutch_auction.bid(sender=keys[bidder_1], value=value_1)
        self.assertEqual(self.dutch_auction.calcStopPrice(), bid_amount_1 / 9000000 + 1)
        # 60 days later
        days_later = self.BLOCKS_PER_DAY*60
        self.s.block.number += days_later
        self.assertEqual(self.dutch_auction.calcTokenPrice(), 4000 * 10**18 / (days_later + 7500) + 1)
        self.assertGreater(self.dutch_auction.calcTokenPrice(), self.dutch_auction.calcStopPrice())
        # Bidder 2 places a bid
        bidder_2 = 1
        value_2 = 150000 * 10**18  # 100k Ether
        self.s.block.set_balance(accounts[bidder_2], value_2*2)
        bid_amount_2 = self.dutch_auction.bid(sender=keys[bidder_2], value=value_2)
        # Stop price changed
        self.assertEqual(self.dutch_auction.calcStopPrice(), (bid_amount_1 + bid_amount_2) / 9000000 + 1)
        # Auction is instantly over since stop price already higher than token price
        self.assertRaises(TransactionFailed, self.dutch_auction.bid, sender=keys[bidder_2], value=1)
        self.assertLess(self.dutch_auction.calcTokenPrice(), self.dutch_auction.calcStopPrice())
        # There is no money left in the contract
        self.assertEqual(self.s.block.get_balance(self.dutch_auction.address), 0)
        # Everyone gets their tokens
        self.dutch_auction.claimTokens(sender=keys[bidder_1])
        self.dutch_auction.claimTokens(sender=keys[bidder_2])
        # Confirm token balances
        self.assertEqual(self.gnosis_token.balanceOf(accounts[bidder_1]),
                         bid_amount_1 * 10 ** 18 / self.dutch_auction.finalPrice())
        self.assertEqual(self.gnosis_token.balanceOf(accounts[bidder_2]),
                         bid_amount_2 * 10 ** 18 / self.dutch_auction.finalPrice())
        self.assertEqual(
            self.gnosis_token.balanceOf(self.multisig_wallet.address),
            self.TOTAL_TOKENS - self.dutch_auction.totalReceived() * 10 ** 18 / self.dutch_auction.finalPrice())
        self.assertEqual(self.gnosis_token.totalSupply(), self.TOTAL_TOKENS)
        # All funds went to the multisig wallet
        self.assertEqual(self.s.block.get_balance(self.multisig_wallet.address), bid_amount_1 + bid_amount_2)
