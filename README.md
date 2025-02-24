# Tokenize Real Estate

Tokenizing real estate enables fractional ownership, making real-world properties more accessible to investors. This project utilizes Chainlink Functions to source real estate data from an external API and mints fractionalized tokens on the Avalanche Fuji testnet using the ERC-1155 standard.

## Data Sourcing & Tokenization
The real estate data is sourced from [Zillow](https://bridgedataoutput.com/docs/explorer/reso-web-api#oShowProperty) via Chainlink Functions. The fractionalized property ownership is represented through ERC-1155 tokens deployed on Avalanche Fuji.

---

# Smart Contracts

## **RealEstateToken.sol**
This contract represents the fractionalized real estate token system and:

- Inherits cross-chain mint and burn functionality from `CrossChainBurnAndMintERC1155.sol`.
- Manages real estate price details via `RealEstatePriceDetails.sol`.
- Utilizes `FunctionsSource.sol` to provide JavaScript code for Chainlink Functions requests.

## **Issuer.sol**
The `Issuer.sol` contract facilitates the issuance of fractionalized real estate NFTs. It integrates Chainlink Functions to retrieve metadata off-chain and ensures that only one issuance request is processed at a time.

## **EnglishAuction.sol**
This contract implements an English auction mechanism for fractionalized ERC-1155 real estate tokens. The auction runs for 7 days, allowing users to place bids, with the highest bidder securing ownership at the end.

## **RwaLending.sol**
`RwaLending.sol` enables lending against real estate-backed ERC-1155 tokens. It integrates Chainlink Price Feeds to fetch real-time USDC valuations and supports borrowing, repayment, and liquidation functionalities.

---

# Services & Integrations

## **Real Estate Data Fetching via Chainlink Functions**
Chainlink Functions is used to fetch real estate data from Zillow's API. The `RealEstatePriceDetails.sol` contract manages price updates, while `FunctionsSource.sol` provides the JavaScript implementation for the Chainlink Functions request.

## **Cross-Chain Transfers with Chainlink CCIP**
The `RealEstateToken.sol` contract is deployed on both Avalanche Fuji and Base Sepolia. It utilizes `CrossChainBurnAndMintERC1155.sol` to enable seamless cross-chain transfers while ensuring accurate real estate price data via Chainlink Functions.

## **Automated Price Updates with Chainlink Automation**
Chainlink Automation is used to regularly update the price details of fractionalized real estate tokens in a decentralized manner.

## **USDC Price Fetching via Chainlink Price Feeds**
To ensure accurate valuations, Chainlink Price Feeds provide real-time USDC pricing in terms of USD.

---


# Addresses 

RealEstateToken deployed on Avalanche Fuji at: [0xb8c7e1f97C2D6C1893B1fEe7D0c42A9468761908](https://testnet.snowtrace.io/address/0xb8c7e1f97C2D6C1893B1fEe7D0c42A9468761908)

RealEstateToken deployed on Ethereum Sepolia at: [0x887a5Dd013F5A8a568e9AF4F73E6f8F069057953](https://sepolia.etherscan.io/address/0x887a5dd013f5a8a568e9af4f73e6f8f069057953)

RealEstateToken deployed on Base Sepolia at: [0x9768C04C9bC6297bB97ebc7FdE519018A693Bc86](https://sepolia.basescan.org/address/0x9768C04C9bC6297bB97ebc7FdE519018A693Bc86)

Issuer deployed on Avalanche Fuji at: [0x1922968E9A8131FEda8bD04c1dD0312A78a0356C](https://testnet.snowtrace.io/address/0x1922968E9A8131FEda8bD04c1dD0312A78a0356C)

RwaLending contract deployed on Avalanche Fuji at: [0xa0dE9f0c2626462E1fEf5db158FF0350e3F94215](https://testnet.snowtrace.io/address/0xa0dE9f0c2626462E1fEf5db158FF0350e3F94215)

EnglishAuction contract on Avalanche Fuji deployed at: [0x7E249d1fd26a15e7980E81d85eEcAb42f53E33DF](https://testnet.snowtrace.io/address/0x7E249d1fd26a15e7980E81d85eEcAb42f53E33DF)

Chainlink Automation forwarder Avalanche Fuji address : [0x363F605102b11a792052554D386DDD69bD6b6f2b](https://testnet.snowtrace.io/address/0x363F605102b11a792052554D386DDD69bD6b6f2b)

---

This project showcases how blockchain and decentralized oracles can enable real-world asset tokenization, making real estate investments more accessible and efficient.