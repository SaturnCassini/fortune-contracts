# Fortune Contracts

ERC20 contract for Fortune tokens of [Saturn Series](https://saturnseries.com).

<p align="center">
  <img src="public/card.png" height="350" alt="Fortune Card Illustration" title="Fortune Cards Contract">
</p>

--

##  Overview
1. Legends can mint a Fortune Card ERC20 once per day, and optionally add a tribue to their fortune. Legends can only have one Fortune Card minted at a time.
2. The Fortune Card is transferrable
3. The Fortune Card holder needs to wait 5 minutes to allow the blockchain to make enough randomness data and normalize potential results (this reduces the possibility of an MEV attack from happening)
4. The holder of the Fortune Card can then burn the card. This emits an event of GOOD or BAD fortune. 
5. If the event is GOOD, then the initially paid tribute is returned to the account that burned the Fortune card, minus a set fee. If the fortune is BAD, the funds are returned to the burner, minus the fee.
6. The tribute chest accumulates fees over time, and that balance can be withdrawn by the owner of the contract. 

The system implements one ERC20 token called FORTUNE
The token can be minted with a cooldown of one token per day
The token is transferrable
The FORTUNE can be burned to emit an event of GOOD and BAD fortunes.
There is no cooldown to burn fortunes.

The FORTUNE tokens have unlimited supply, but can only be minted by Saturn Series Legend NFT holders

The output of good or bad has been naively randomized, it uses a mix of `block.prevrandao`, `block.timestamp`, and the optional gwei sent as a tribute (`msg.value`) to calculate if the event is GOOD or BAD.

The challenge of the game consists on using any means possible (MEV) to get as many GOOD fortune events emited for burning the FORTUNE tokens.

# Getting Started
Create the environment
`python3 -m venv`

Activate the environmante
`source venv/bin/activate`


Change directories
`cd contracts`

# Installation
`ape plugins install .` install the dependencies listed in the ape-config.yaml
`ape test`

# Compile
`ape compile`
