import pytest 
import math


def test_mint_nft(mockedNFT,sudo):
    mockedNFT.mintNFT(sudo, sender=sudo)
    balance = mockedNFT.balanceOf(sudo, sender=sudo)
    print(balance)
    assert balance == 1

def test_withdraw_tribute_after_fortunes_burned(mockedNFT, fortune, sudo, chain):
    mockedNFT.mintNFT(sudo, sender=sudo)

    tribute = 123123

    # Play the game a couple times
    for i in range(3):
        # Time travel 25 hours
        chain.pending_timestamp += 3600*25
        chain.mine(4)
        fortune.mintFortune(sudo, sender=sudo, value=tribute)
        assert fortune.fortuneBalance(sudo) == 1 
        chain.pending_timestamp += 60*6
        chain.mine(4)
        fortune.burnFortune(sender=sudo) 

    assert fortune.tributeBalance() == 0
    assert fortune.feesBalance() == math.floor(tribute *3*0.05)
    fortune.withdrawFees(sender=sudo)
    assert fortune.feesBalance() == 0

def test_transfer_card_and_earn_tribute(mockedNFT, fortune, sudo, chain, dev):
    mockedNFT.mintNFT(sudo, sender=sudo)
    tribute = int(1e18)
    fortune.mintFortune(sudo, sender=sudo, value=tribute)
    assert fortune.fortuneBalance(sudo) == 1
    assert fortune.tributeBalance() == math.floor(tribute * 0.95)
    assert fortune.feesBalance() == math.floor(tribute * 0.05)
    fortune.transfer(dev, 1, sender=sudo)
    assert fortune.fortuneBalance(sudo) == 0
    assert fortune.fortuneBalance(dev) == 1
    assert fortune.tributeBalance() == math.floor(tribute * 0.95)
    assert fortune.feesBalance() == math.floor(tribute * 0.05)
    print(dev.balance)
    fortune.burnFortune(sender=dev)
    assert fortune.fortuneBalance(sudo) == 0
    assert fortune.fortuneBalance(dev) == 0
    print(dev.balance)
    print(fortune.balance)

    assert fortune.tributeBalance() == 0
    assert fortune.feesBalance() == math.floor(tribute * 0.05)
    assert dev.balance() ==  math.floor(tribute *0.95)

def test_mint_fortune(fortune, sudo):
    # Should not allow you to mint if youre not a legend
    with pytest.raises(Exception):
        fortune.mintFortune(sudo, sender=sudo)

    
def test_fortune_burn_must_wait(mockedNFT, fortune, sudo):
    mockedNFT.mintNFT(sudo, sender=sudo)
    fortune.mintFortune(sudo, sender=sudo)
    with pytest.raises(Exception):
        fortune.burnFortune(sender=sudo) == True

def test_fortune_burn(mockedNFT, fortune, sudo,chain):
    mockedNFT.mintNFT(sudo, sender=sudo)
    fortune.mintFortune(sudo, sender=sudo)
    assert fortune.fortuneBalance(sudo) == 1
    # Time travel 24 hours
    chain.pending_timestamp += 60*6
    chain.mine(4)
    fortune.burnFortune(sender=sudo) 
    assert fortune.fortuneBalance(sudo) == 0

# @pytest.mark.skip('not implemented')
def test_tribute_balance_changes_after_mint(mockedNFT, fortune, sudo, chain):
    tribute = 10000
    rounds = 20
    # sudo.balance += int(1e18)
    for i in range(rounds):
        # Time travel 24 hours
        chain.pending_timestamp += 3600*25
        chain.mine(4)
        mockedNFT.mintNFT(sudo, sender=sudo)
        fortune.mintFortune(sudo, sender=sudo, value=tribute)
        assert fortune.fortuneBalance(sudo) == 1
        assert fortune.tributeBalance() > 0
        chain.pending_timestamp += 60*6
        chain.mine(4)
        fortune.burnFortune(sender=sudo) 
        print("feesBalance:", fortune.feesBalance())

    
    print(fortune.tributeBalance())
    assert int(fortune.tributeBalance()) == 0
    print(fortune.feesBalance())
    assert fortune.feesBalance() == math.floor(tribute *rounds*0.05) 


def test_transfer_fortune_and_burn_it(mockedNFT, fortune, sudo, chain, accounts):
    mockedNFT.mintNFT(sudo, sender=sudo)
    fortune.mintFortune(sudo, sender=sudo)
    assert fortune.fortuneBalance(sudo) == 1
    assert fortune.fortuneBalance(accounts[1]) == 0
    fortune.transfer(accounts[1], 1, sender=sudo)
    assert fortune.fortuneBalance(sudo) == 0
    assert fortune.fortuneBalance(accounts[1]) == 1

    # Time travel 24 hours
    chain.pending_timestamp += 60*6
    chain.mine(4)
    fortune.burnFortune(sender=accounts[1])
    assert fortune.fortuneBalance(accounts[1]) == 0



def test_minting_twice_should_revert(mockedNFT, fortune, sudo, chain):
    tribute=100
    mockedNFT.mintNFT(sudo, sender=sudo)
    fortune.mintFortune(sudo, value=tribute, sender=sudo)
    assert fortune.tributeBalance() == math.floor(tribute * 0.95)
    chain.pending_timestamp += 60*6
    chain.mine(4)
    assert fortune.fortuneBalance(sudo) == 1
    with pytest.raises(Exception):
        fortune.mintFortune(sudo, sender=sudo)

def test_winning_still_uses_funds(mockedNFT, fortune, sudo, chain):
    mockedNFT.mintNFT(sudo, sender=sudo)
    fortune.mintFortune(sudo, sender=sudo, value=10000)
    assert fortune.fortuneBalance(sudo) == 1
    assert fortune.tributeBalance() > 0
    chain.pending_timestamp += 60*6
    chain.mine(4)
    fortune.burnFortune(sender=sudo)
    assert fortune.fortuneBalance(sudo) == 0
    
def test_minting_multiple_increases_card_number(mockedNFT, fortune, sudo, chain):
    mockedNFT.mintNFT(sudo, sender=sudo)
    tribute = 100
    loops = 3
    for i in range(loops):
        print(i)
        fortune.mintFortune(sudo, sender=sudo, value=tribute)
        #Mints only once
        assert fortune.fortuneBalance(sudo) == 1 
        # Fast forward 1 day to be able to burn and mint again
        chain.pending_timestamp += 3600*25
        chain.mine(4)
        fortune.burnFortune(sender=sudo)
        assert fortune.fortuneBalance(sudo) == 0

    assert fortune.currentCardIdFrom(sudo) == loops-1

def test_update_fee(mockedNFT, fortune, sudo, chain):
    # set the fee to 10%
    newFee = 10
    mockedTribute = 100

    # update the fee
    fortune.setTributeFee(newFee, sender=sudo)
    assert fortune.getTributeFee() == newFee

    # mint a fortune
    mockedNFT.mintNFT(sudo, sender=sudo)
    fortune.mintFortune(sudo, sender=sudo, value=mockedTribute)
    assert fortune.fortuneBalance(sudo) == 1
    assert fortune.tributeBalance() > 0
    print(fortune.tributeBalance())
    assert fortune.tributeBalance() == math.floor(mockedTribute*((100-newFee)/100))

    # burn the fortune
    chain.pending_timestamp += 60*6
    chain.mine(4)
    fortune.burnFortune(sender=sudo)
    print(fortune.tributeBalance())
    assert fortune.fortuneBalance(sudo) == 0

def test_events_from_nft_mints(mockedNFT, sudo):
    for i in range(5):
        mockedNFT.mintNFT(sudo, sender=sudo)
    logs = []
    for new_log in mockedNFT.Mint.range(start_or_stop=0, stop=10):
        print(f"New event log found: block_number={new_log.block_number}")
        print(new_log.event_arguments)
        logs.append(new_log.event_arguments)

    assert len(logs) == 5

def test_events_from_fortune_burns(mockedNFT, sudo, fortune, chain):
    for i in range(10):
        mockedNFT.mintNFT(sudo, sender=sudo)
        fortune.mintFortune(sudo, sender=sudo)
        chain.pending_timestamp += 3600*25
        chain.mine(4)
        fortune.burnFortune(sender=sudo)
    
    results = []
    for new_log in fortune.BurnFortune.range(start_or_stop=0, stop=100):
        print(f"New event log found: block_number={new_log.block_number}")
        print(new_log.event_arguments['value'])
        results.append(new_log.event_arguments['value'])

    # This might fail sometimes due to randomnes and it is not a big deal
    assert 'GOOD' in results
    assert 'BAD' in results 


def test_set_owner(mockedNFT, fortune, sudo, accounts):
    fortune.setOwner(accounts[1], sender=sudo)
    assert fortune.owner() == accounts[1]