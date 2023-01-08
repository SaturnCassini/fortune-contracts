# @version ^0.3.7
"""
@Title Mock Saturn Series ERC721 Token
@dev This contract replicates the functionality of the ERC721 standard, but
     with a few differences. It is intended to be used for testing purposes
     only.
@author 0xcassini.eth
"""

event Mint:
    to: indexed(address)

event Burn:
    to: indexed(address)

name: public(String[64])
symbol: public(String[32])
initialSupply: public(uint256)
balances: public(HashMap[address, uint256])
supply: public(uint256)

@external
def __init__(name: String[64], symbol: String[32], initialSupply: uint256):
    """
    @notice Initialize the contract
    @param name The name of the token
    @param symbol The symbol of the token
    @param initialSupply The initial supply of the token
    @param fortuneContract The address of the Fortune ERC20 contract
    """
    self.name = name
    self.symbol = symbol
    self.supply = initialSupply



@payable
@external
def mintNFT(to: address):
    """
    @notice Mint a new mocked NFT
    @param tokenId The ID of the token to mint
    @param to The address to mint the token to
    """
    self.supply += 1
    self.balances[to] += 1
    log Mint(to)

@external
def burnNFT(to: address):
    """
    @notice Burn a mocked NFT
    @param tokenId The ID of the token to burn
    """
    self.supply -= 1
    self.balances[to] -= 1
    log Burn(to)
    
@external
def balanceOf(legend: address) -> uint256:
    """
    @notice Get the balance of a mocked NFT
    @param address The address to get the balance of
    """
    return self.balances[legend]

