import pytest 

def test_mint_nft(mockedNFT,sudo):
    mockedNFT.mintNFT(sudo, sender=sudo)
    balance = mockedNFT.balanceOf(sudo, sender=sudo)
    print(balance)
    assert balance == 1

def test_fortune(fortune, sudo):
    # Should not allow you to mint if youre not a legend
    fortune.mintFortune(sudo, sender=sudo)
    nftBalance = fortune.balanceOf(sudo)
    assert nftBalance == 1
    
def test_fortune_burn_must_wait(mockedNFT, fortune, sudo):
    mockedNFT.mintNFT(sudo, sender=sudo)
    fortune.mintFortune(sudo, sender=sudo)
    assert fortune.burnFortune(sender=sudo) == True

def test_fortune_burn(mockedNFT, fortune, sudo,project):
    mockedNFT.mintNFT(sudo, sender=sudo)
    fortune.mintFortune(sudo, sender=sudo)
    # Time travel 24 hours
    project.time_travel(86400)
    assert fortune.burnFortune(sender=sudo) == True