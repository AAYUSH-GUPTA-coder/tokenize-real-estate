// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * This is the javascript source code for the chainlink functions.
 * source API is Zillow API : https://bridgedataoutput.com/docs/explorer/reso-web-api#oShowProperty
 * https://bridgedataoutput.com/docs/platform/Introduction
 */
abstract contract FunctionsSource {
    /// @notice This is the source code to get the metadata of the NFT like address, year built, lot size, etc.
    string public getNftMetadata = "const { ethers } = await import('npm:ethers@6.10.0');"
        "const Hash = await import('npm:ipfs-only-hash@4.0.0');" "const apiResponse = await Functions.makeHttpRequest({"
        "    url: `https://api.bridgedataoutput.com/api/v2/OData/test/Property('P_5dba1fb94aa4055b9f29696f')?access_token=6baca547742c6f96a6ff71b138424f21`,"
        "});" "const realEstateAddress = apiResponse.data.UnparsedAddress;"
        "const yearBuilt = Number(apiResponse.data.YearBuilt);"
        "const lotSizeSquareFeet = Number(apiResponse.data.LotSizeSquareFeet);"
        "const livingArea = Number(apiResponse.data.LivingArea);"
        "const bedroomsTotal = Number(apiResponse.data.BedroomsTotal);" "const metadata = {"
        "name: `Real Estate Token`," "attributes: [" "{ trait_type: `realEstateAddress`, value: realEstateAddress },"
        "{ trait_type: `yearBuilt`, value: yearBuilt },"
        "{ trait_type: `lotSizeSquareFeet`, value: lotSizeSquareFeet },"
        "{ trait_type: `livingArea`, value: livingArea }," "{ trait_type: `bedroomsTotal`, value: bedroomsTotal }" "]"
        "};" "const metadataString = JSON.stringify(metadata);" "const ipfsCid = await Hash.of(metadataString);"
        "return Functions.encodeString(`ipfs://${ipfsCid}`);";

    /// @notice This is the source code to get the prices of the Property like list price, original list price, tax assessed value, etc.
    string public getPrices = "const { ethers } = await import('npm:ethers@6.10.0');"
        "const abiCoder = ethers.AbiCoder.defaultAbiCoder();" "const tokenId = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
        "    url: `https://api.bridgedataoutput.com/api/v2/OData/test/Property('P_5dba1fb94aa4055b9f29696f')?access_token=6baca547742c6f96a6ff71b138424f21`,"
        "});" "const listPrice = Number(apiResponse.data.ListPrice);"
        "const originalListPrice = Number(apiResponse.data.OriginalListPrice);"
        "const taxAssessedValue = Number(apiResponse.data.TaxAssessedValue);"
        "const encoded = abiCoder.encode([`uint256`, `uint256`, `uint256`, `uint256`], [tokenId, listPrice, originalListPrice, taxAssessedValue]);"
        "return ethers.getBytes(encoded);";
}
