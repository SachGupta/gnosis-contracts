Gnosis Smart Contracts
===================

<img src="assets/logo.png" />

[![Slack Status](http://slack.gnosis.pm/badge.svg)](http://slack.gnosis.pm)

Collection of smart contracts for the Gnosis prediction market platform (https://www.gnosis.pm). To interact with those contracts have a look at (https://github.com/ConsenSys/gnosis.js/).

Install
-------------
```
git clone https://github.com/ConsenSys/gnosis-contracts.git
cd gnosis-contracts
vagrant up
```

Test
-------------
### Run all tests:
```
cd /vagrant/
python -m unittest discover contracts.tests
```

### Run one test:
```
cd /vagrant/
python -m unittest contracts.tests.test_name
```

Deploy
-------------
### Deploy all contracts required for the token auction:
```
cd /vagrant/contracts/
python deploy.py -f deploy/tokenAuction.json
```

Security and Liability
-------------
All contracts are WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

License
-------------
All smart contracts are released under GPL v.3.

Contributors
-------------
- Stefan George ([Georgi87](https://github.com/Georgi87))
- Martin Koeppelmann ([koeppelmann](https://github.com/koeppelmann))
