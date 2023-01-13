import pytest


def test_721_mints_fortune(mockedNFT, f721, sudo):
    f721.mintFortune(sudo, 0, sender=sudo)
    assert f721.balanceOf(sudo) == 1

def test_721_mints_once_a_day(mockedNFT, f721, sudo, chain):
    f721.mintFortune(sudo, 0, sender=sudo)
    assert f721.balanceOf(sudo) == 1
    with pytest.raises(Exception):
        f721.mintFortune(sudo, 1, sender=sudo)
    chain.pending_timestamp += 3600*25  
    chain.mine(4)
    f721.mintFortune(sudo, 1, sender=sudo)
    assert f721.balanceOf(sudo) == 2