# @version ^0.3.7

"""
@title Bare-bones Token implementation of the Fortune cards
@notice This is a bare-bones implementation of the Fortune cards
        It is not meant to be used in production, but rather as a
        starting point for the final implementation
        
        Owners of the Legends NFT can mint an unrevealed Fortune
        card as an ERC20 to any address, and pay an upfront tribute.

        The Fortune cards can be burned to generate an event of GOOD or BAD
        fortune. The event is a string of 4 characters, which can be used
        by the frontend to display a message, and for the game to build upon it later.
    
        The Fortune cards can be traded, but only the owner of the NFT can mint
        a new Fortune card.

        When the FORTUNE card is burnt, the burner can get back their initial tribute minus a fee.

        There is a withdraw function that can only be called by the owner of the contract.
        This is to allow the owner to withdraw the ETH tributes.

@author 0xcassini.eth
"""


interface LegendsContract:
    def balanceOf(_owner: address) -> uint256: view

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event MintFortune:
    receiver: indexed(address)
    value: uint256

event BurnFortune:
    legend: indexed(address)
    value: String[4]
    fortune: FortuneCard

# The Fortune card is an ERC20 token that is tied to the value of the tribute it was minted with
struct FortuneCard:
    cardNumber: uint256
    tributeAmount: uint256
    dateMinted: uint256
    randomness: uint256

name: public(String[64])
symbol: public(String[32])
circulatingSupply: public(uint256)
legendsContract: LegendsContract

# The mapping of the Fortune cards
# The key is the address of the minter of the token
# The value is the Fortune card's msg.value
fortunesLog: HashMap[address, FortuneCard]

# Used to keep track of the number of Fortune cards minted
mintCount: public(uint256)

balances: HashMap[address, uint256]
allowances: HashMap[address, HashMap[address, uint256]]
lastMinted: HashMap[address, uint256]

fortuneContract: public(address)
tributeBalance: public(uint256)
tributeFee: public(uint256)
feesBalance: public(uint256)

owner: public(address)

@external
def __init__(_name: String[64], _symbol: String[32], _initial_supply: uint256, legendsAddress: address, tributeFee: uint256):
    self.name = _name
    self.symbol = _symbol
    self.balances[msg.sender] = _initial_supply
    self.circulatingSupply = _initial_supply
    self.legendsContract = LegendsContract(legendsAddress)
    self.owner = msg.sender
    self.tributeFee = tributeFee
    log Transfer(empty(address), msg.sender, _initial_supply)
    

@view
@external
def fortuneBalance(_owner: address) -> uint256:
    """
    @notice Getter to check the current balance of an address
    @param  _owner Address to query the balance of
    @return Token balance
    """
    return self.balances[_owner]


@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    """
    @notice Getter to check the amount of tokens that an owner allowed to a spender
    @param  _owner The address which owns the funds
    @param  _spender The address which will spend the funds
    @return The amount of tokens still available for the spender
    """
    return self.allowances[_owner][_spender]

@nonpayable
@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
    @dev    Beware that changing an allowance with this method brings the risk that someone may use both the old
            and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
            race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
            https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param  _spender The address which will spend the funds.
    @param  _value The amount of tokens to be spent.
    @return Success boolean
    """
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@internal
def _transfer(_from: address, _to: address, _value: uint256):
    """
    @dev    Internal shared logic for transfer and transferFrom
    @param  _from The address which you want to send tokens from
    @param  _to The address which you want to transfer to
    @param  _value The amount of tokens to be transferred
    """
    assert self.balances[_from] >= _value, "Insufficient balance"
    self.balances[_from] -= _value
    self.balances[_to] += _value
    log Transfer(_from, _to, _value)

@nonpayable
@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @notice Transfer tokens to a specified address
    @dev    Vyper does not allow underflows, so attempting to transfer more
            tokens than an account has will revert
    @param  _to The address to transfer to
    @param  _value The amount to be transferred
    @return Success boolean
    """
    self._transfer(msg.sender, _to, _value)
    return True

@nonpayable
@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
    @notice Transfer tokens from one address to another
    @dev    Vyper does not allow underflows, so attempting to transfer more
            tokens than an account has will revert
    @param  _from The address which you want to send tokens from
    @param  _to The address which you want to transfer to
    @param  _value The amount of tokens to be transferred
    @return Success boolean
    """
    assert self.allowances[_from][msg.sender] >= _value, "Insufficient allowance"
    self.allowances[_from][msg.sender] -= _value
    self._transfer(_from, _to, _value)
    return True

@payable
@external
def mintFortune(to: address) -> bool:
    """
    @notice Mint a fortune to an specified address which holds the nft
    @dev    this is not yet tested and should be used with caution
    @dev    You could add an assert here to make sure the owner of the nft is the one who can mint
    @param  to who receives the fortune
    @return True if the caller addres is a legend
    """
    # Make sure the minter doesnt have a fortune already
    assert self.balances[msg.sender] == 0, "First burn your current fortune"
    if self.legendsContract.balanceOf(msg.sender) > 0:               # if the caller is a legend
        if self.lastMinted[msg.sender] + 3600*24 > block.timestamp:  # and if less 24 hours passed since last mint
            raise "You can only mint once a day"                     #     then raise error
        else:                                                        # else mint the fortune...
            self.circulatingSupply += 1                              #      increase circulating supply
            self.balances[msg.sender] += 1                           #      add fortune to the minter hashmap
            self.lastMinted[msg.sender] = block.timestamp            #      update last minted of the minter hashmap
            self.tributeBalance += msg.value * (100-self.tributeFee) / 100  # add the tribute to the tribute balance   
            self.feesBalance += msg.value * self.tributeFee/100     #      add the fees to feesBalance  
            self.fortunesLog[msg.sender] = FortuneCard({             #      add the fortune to the log hashmap
                cardNumber: self.mintCount,                          #      the mint count is the card number
                tributeAmount: msg.value,                            #      the tribute is in ehter, equal to the amount in the msg.value  
                dateMinted: block.timestamp,                         #      the date minted is the current block timestamp
                randomness: block.prevrandao,                        #      <--- ! The randomness is the previous block randao, this helps MEV protection
                }
            )
            self.mintCount += 1                                      #      increase the mint count                  
            log MintFortune(msg.sender, 1)                           #      emit the event and log the mint
            return True                                              #      return true
    else:
        raise "Not a Legend"                                         # if the caller is not a legend, raise error               

@external
def burnFortune():
    """
    @notice Burn a fortune from an specified address
    @dev    this is not yet tested and should be used with caution
    @dev    You could add an assert here to make sure the owner of the nft is the one who can burn
    """
    currentFortune: FortuneCard = self.fortunesLog[msg.sender]
    assert self.balances[msg.sender] >= 1, "You dont have a fortune to burn"
    assert block.timestamp > currentFortune.dateMinted + 300 , "Wait at least 5 minutes to burn your fortune"
    self.circulatingSupply -= 1
    self.balances[msg.sender] -= 1

    # Check if the fortune is good or bad
    
    # This is the randomness function that will decide if the fortune is good or bad
    # It takes various internal properties of the contract and the block and adds them together to generate a random seed
    # This seed also includes the block's prevrandao (see: -> https://eips.ethereum.org/EIPS/eip-4399#security-considerations)
    # Then it divides by 2087 which is a prime number, and checks if the remainder is even or odd
    # If even, the fortune is good, if odd, the fortune is bad
    reward: uint256 = currentFortune.tributeAmount * (100-self.tributeFee) / 100
    if (( self.balance + block.prevrandao + currentFortune.dateMinted + currentFortune.randomness + currentFortune.cardNumber) % 2087) % 2 == 0:
        log BurnFortune(msg.sender, 'GOOD', currentFortune)         # emit the event and log the good fortune burn
    else:
        log BurnFortune(msg.sender, 'BAD', currentFortune)          # emit the event and log the bad fortune burn  
    self.tributeBalance -= reward                                   # remove the reward from the tribute balance    
    send(msg.sender, reward)                                        # send the reward to the caller

@view
@external
def currentCardIdFrom(legend:address)-> uint256:
    """
    @notice Getter to check the current cardNumber of an address
            This is useful because legends can only have one fortune at a time
    """
    return self.fortunesLog[legend].cardNumber

@view
@external
def getLegendBalance() -> uint256:
    """
    @notice Getter to check the current balance of an address
    @dev    this is not yet tested and should be used with caution
    """
    legends: LegendsContract = self.legendsContract
    return legends.balanceOf(msg.sender)

@view
@external
def getFortuneChestBalance() -> uint256:
    """
    @notice Getter to check the current ETH balance of the fortune chest
    @dev    This is not yet tested and should be used with caution
    @return ETH balance
    """
    return self.balance

@view
@external
def getTributeFee()-> uint256:
    """
    @notice Getter to check the current tribute fee
    @return tribute fee
    """
    return self.tributeFee

# Admin functions

@view
@external
def currentOwner() -> address:
    """
    @notice Getter to check the current owner of the fortune chest
    """
    return self.owner 
    
@external
def setOwner(new_owner:address) -> bool:
    """
    @notice Setter to set the owner of the fortune chest
    @dev    this is not yet tested and should be used with caution
    @dev    You could add an assert here to make sure the owner of the nft is the one who can burn
    @param  new_owner The address that will be the new owner of the contract
    @return Success boolean
    """
    assert self.owner == msg.sender     # make sure the caller is the owner
    if self.owner == msg.sender:        
        self.owner = new_owner          # set the new owner
        return True
    else:
        raise "Not the owner"           # if the caller is not the owner, raise error


@external
def rugPull() -> bool:
    """
    @notice Withdraw all the ETH from the fortune chest
    @dev    this is not yet tested and should be used with caution
    @return Success boolean
    """
    assert self.owner == msg.sender
    assert self.balance > 0
    if self.owner == msg.sender:
        send(self.owner, self.balance)
        self.tributeBalance = 0
        return True
    else:
        raise "Not the contract Owner"


@external
def withdrawFees() -> bool:
    """
    @notice Withdraw all the fees from the fortune chest
    @dev    this is not yet tested and should be used with caution
    @return Success boolean
    """
    assert self.owner == msg.sender
    assert self.feesBalance > 0
    if self.owner == msg.sender:
        send(self.owner, self.feesBalance)
        self.feesBalance = 0
        return True
    else:
        raise "Not the contract Owner"

@external
def setTributeFee(percentage: uint256)-> bool:
    """
    @notice Setter to set the tribute fee
    @dev    this is not yet tested and should be used with caution
    @dev    You could add an assert here to make sure the owner of the nft is the one who can burn
    @param  percentage The percentage of the tribute that will be taken
    @return Success boolean
    """
    assert self.owner == msg.sender   # only the owner can set the fee
    if self.owner == msg.sender:      # double check, only the owner can set the fee
        assert percentage <= 10       # the fee cannot be more than 10% ever
        self.tributeFee = percentage  # set the fee
        return True
    else:
        raise "Not the contract Owner" # if somehow the caller is not the owner, raise error