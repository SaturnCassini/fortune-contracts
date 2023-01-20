import pytest


def test_721_mints_fortune(mockedNFT, f721, sudo):
    mockedNFT.mintNFT(sudo, sender=sudo)
    f721.mintFortune(sudo, sender=sudo)
    assert f721.balanceOf(sudo) == 1

def test_721_mints_once_a_day(mockedNFT, f721, sudo, chain):
    mockedNFT.mintNFT(sudo, sender=sudo)
    f721.mintFortune(sudo, sender=sudo)
    assert f721.balanceOf(sudo) == 1
    with pytest.raises(Exception):
        f721.mintFortune(sudo, sender=sudo)
    chain.pending_timestamp += 3600*25  
    chain.mine(4)
    f721.mintFortune(sudo, sender=sudo)
    assert f721.balanceOf(sudo) == 2

def test_burning_with_no_wait_raises_error(mockedNFT, f721, sudo, chain):
    mockedNFT.mintNFT(sudo, sender=sudo)    
    f721.mintFortune(sudo, sender=sudo)
    assert f721.balanceOf(sudo) == 1
    with pytest.raises(Exception):
        f721.burnFortune(1, sender=sudo)

def test_721_burns_fortune_after_some_time(mockedNFT, f721, sudo, chain):
    mockedNFT.mintNFT(sudo, sender=sudo)    
    f721.mintFortune(sudo, sender=sudo)
    assert f721.balanceOf(sudo) == 1
    chain.pending_timestamp += 3600*25  
    chain.mine(4)
    f721.burnFortune(1, sender=sudo)
    assert f721.balanceOf(sudo) == 0

def test_fees_system_sets_fees(mockedNFT, f721, sudo, chain):
    f721.setFees(10, sender=sudo)
    assert f721.feesRate() == 10

def test_fees_system_accrues_fees_upon_minting(mockedNFT, f721, sudo):
    mockedNFT.mintNFT(sudo, sender=sudo)
    f721.setFees(10, sender=sudo)    
    f721.mintFortune(sudo, sender=sudo, value=100)
    assert f721.feesBalance() == 10

def test_fees_can_be_withdrawn(mockedNFT, f721, sudo):
    mockedNFT.mintNFT(sudo, sender=sudo)
    f721.setFees(5, sender=sudo)
    f721.mintFortune(sudo, sender=sudo, value=100)
    assert f721.feesBalance() == 5
    f721.withdrawFees(sender=sudo)
    assert f721.feesBalance() == 0

def test_721_burns_fortune_returns_fees_to_burner(mockedNFT, f721, sudo, chain):
    tribute = 100
    mockedNFT.mintNFT(sudo, sender=sudo)    
    f721.mintFortune(sudo, sender=sudo, value=tribute)
    assert f721.balanceOf(sudo) == 1
    assert f721.tributesPlaying() == tribute - 5
    chain.pending_timestamp += 3600*25  
    chain.mine(4)
    f721.burnFortune(1, sender=sudo)
    assert f721.balanceOf(sudo) == 0
    assert f721.feesBalance() == 5
    assert f721.tributesPlaying() == 0

def test_set_owner(fortune, sudo, accounts):
    fortune.setOwner(accounts[1], sender=sudo)
    assert fortune.owner() == accounts[1]
    with pytest.raises(Exception):
        fortune.setOwner(accounts[2], sender=sudo)