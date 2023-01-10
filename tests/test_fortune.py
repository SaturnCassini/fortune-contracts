import pytest 

def test_mint_nft(mockedNFT,sudo):
    mockedNFT.mintNFT(sudo, sender=sudo)
    balance = mockedNFT.balanceOf(sudo, sender=sudo)
    print(balance)
    assert balance == 1

def test_fortune(fortune, sudo):
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
    # sudo.balance += int(1e18)
    for i in range(20):
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
    
    assert int(fortune.tributeBalance()) > 0 
    print(fortune.tributeBalance())
    assert fortune.tributeLost() > 0


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

