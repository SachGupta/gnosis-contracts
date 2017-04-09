from ..abstract_test import AbstractTestContract, accounts, keys


class TestContract(AbstractTestContract):
    """
    run test with python -m unittest contracts.tests.do.test_vesting
    """

    BACKER_1 = 1
    BACKER_2 = 2
    BLOCKS_PER_DAY = 5760
    TOTAL_TOKENS = 10000000 * 10**18
    MAX_TOKENS_SOLD = 9000000 * 10**18
    PREASSIGNED_TOKENS = 1000000 * 10**18
    WAITING_PERIOD = 60*60*24*7
    MAX_GAS = 150000  # Kraken gas limit
    ONE_YEAR = 60*60*24*365
    FUNDING_GOAL = 250000 * 10**18
    START_PRICE_FACTOR = 4000

    def __init__(self, *args, **kwargs):
        super(TestContract, self).__init__(*args, **kwargs)
        self.deploy_contracts = [self.dutch_auction_name]

    def test(self):
        start_date = self.s.block.timestamp
        # Create wallet
        required_accounts = 1
        wa_1 = 1
        constructor_parameters = (
            [accounts[wa_1]],
            required_accounts
        )
        self.multisig_wallet = self.s.abi_contract(
            self.pp.process(self.WALLETS_DIR + 'MultiSigWalletWithDailyLimit.sol', add_dev_code=True,
                            contract_dir=self.contract_dir),
            language='solidity',
            constructor_parameters=constructor_parameters
        )
        # Create vesting contracts
        self.vesting_1 = self.s.abi_contract(self.pp.process(self.DO_DIR + 'Vesting.sol',
                                                             add_dev_code=True,
                                                             contract_dir=self.contract_dir),
                                             language='solidity',
                                             constructor_parameters=[accounts[0], self.multisig_wallet.address])
        self.vesting_2 = self.s.abi_contract(self.pp.process(self.DO_DIR + 'Vesting.sol',
                                                             add_dev_code=True,
                                                             contract_dir=self.contract_dir),
                                             language='solidity',
                                             constructor_parameters=[accounts[1], self.multisig_wallet.address])
        # Create Gnosis token
        self.gnosis_token = self.s.abi_contract(self.pp.process(self.gnosis_token_name,
                                                                add_dev_code=True,
                                                                contract_dir=self.contract_dir),
                                                language='solidity',
                                                constructor_parameters=(self.dutch_auction.address,
                                                                        [self.vesting_1.address,
                                                                         self.vesting_2.address],
                                                                        [self.PREASSIGNED_TOKENS / 2,
                                                                         self.PREASSIGNED_TOKENS / 2]))
        # Create dutch auction
        self.dutch_auction.setup(self.gnosis_token.address,
                                 self.multisig_wallet.address)
        # Set funding goal
        change_ceiling_data = self.dutch_auction.translator.encode('changeSettings',
                                                                   [self.FUNDING_GOAL, self.START_PRICE_FACTOR])
        self.multisig_wallet.submitTransaction(self.dutch_auction.address, 0, change_ceiling_data, sender=keys[wa_1])
        # Start auction
        start_auction_data = self.dutch_auction.translator.encode('startAuction', [])
        self.multisig_wallet.submitTransaction(self.dutch_auction.address, 0, start_auction_data, sender=keys[wa_1])
        # End auction
        value = self.FUNDING_GOAL * 10 ** 18
        spender = 9
        self.s.block.set_balance(accounts[spender], value * 2)
        self.dutch_auction.bid(accounts[spender], sender=keys[spender], value=value)
        # We wait for one week
        self.s.block.timestamp += self.WAITING_PERIOD + 1
        # Token is launched
        self.assertEqual(self.dutch_auction.updateStage(), 3)
        # Test vesting
        self.assertEqual(self.gnosis_token.balanceOf(self.vesting_1.address), self.PREASSIGNED_TOKENS/2)
        self.assertEqual(self.gnosis_token.balanceOf(self.vesting_2.address), self.PREASSIGNED_TOKENS/2)
        # After one year, 1/4 of shares can be withdrawn
        self.s.block.timestamp = start_date + self.ONE_YEAR
        self.assertEqual(self.vesting_1.calcMaxWithdraw(self.gnosis_token.address), self.PREASSIGNED_TOKENS/2/4)
        self.assertEqual(self.vesting_2.calcMaxWithdraw(self.gnosis_token.address), self.PREASSIGNED_TOKENS/2/4)
        # After two years, 1/2 of shares can be withdrawn
        self.s.block.timestamp += self.ONE_YEAR
        self.assertEqual(self.vesting_1.calcMaxWithdraw(self.gnosis_token.address), self.PREASSIGNED_TOKENS/2/2)
        self.assertEqual(self.vesting_2.calcMaxWithdraw(self.gnosis_token.address), self.PREASSIGNED_TOKENS/2/2)
        # Owner withdraws shares
        self.vesting_1.withdraw(self.gnosis_token.address, accounts[8], self.vesting_1.calcMaxWithdraw(self.gnosis_token.address))
        self.assertEqual(self.vesting_1.calcMaxWithdraw(self.gnosis_token.address), 0)
        self.assertEqual(self.gnosis_token.balanceOf(self.vesting_1.address), self.PREASSIGNED_TOKENS/4)
        # Wallet withdraws remaining tokens
        wallet_withdraw_data = self.vesting_1.translator.encode('walletWithdraw', [self.gnosis_token.address])
        old_balance = self.gnosis_token.balanceOf(self.multisig_wallet.address)
        old_vesting_balance = self.gnosis_token.balanceOf(self.vesting_1.address)
        self.multisig_wallet.submitTransaction(self.vesting_1.address, 0, wallet_withdraw_data, sender=keys[wa_1])
        self.assertEqual(self.vesting_1.calcMaxWithdraw(self.gnosis_token.address), 0)
        self.assertEqual(self.gnosis_token.balanceOf(self.vesting_1.address), 0)
        self.assertEqual(self.gnosis_token.balanceOf(self.multisig_wallet.address), old_balance + old_vesting_balance)
