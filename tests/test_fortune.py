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
    assert fortune.balanceOf(sudo) == 1
    # Time travel 24 hours
    chain.pending_timestamp += 60*6
    chain.mine(4)
    fortune.burnFortune(sender=sudo) 
    assert fortune.balanceOf(sudo) == 0