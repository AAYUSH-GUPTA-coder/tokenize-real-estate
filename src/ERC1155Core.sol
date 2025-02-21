// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC1155Supply, ERC1155} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {OwnerIsCreator} from "@chainlink/contracts-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";

/**
 * @title ERC1155Core
 * @dev Core ERC1155 token contract with issuer control and URI management
 */
contract ERC1155Core is ERC1155Supply, OwnerIsCreator {
    // Address of the issuer who can mint and burn tokens
    address internal s_issuer;

    // Mapping to store individual token URIs (tokenId => URI)
    mapping(uint256 tokenId => string) private _tokenURIs;

    // Event emitted when issuer is set or updated
    event SetIssuer(address indexed issuer);

    // Custom error for unauthorized access
    error ERC1155Core_CallerIsNotIssuerOrItself(address msgSender);

    /**
     * @dev Modifier to restrict function access to issuer or contract itself
     */
    modifier onlyIssuerOrItself() {
        if (msg.sender != address(this) && msg.sender != s_issuer) {
            revert ERC1155Core_CallerIsNotIssuerOrItself(msg.sender);
        }
        _;
    }

    /**
     * @dev Constructor sets the initial URI for all token types
     * @param uri_ The base URI with ID substitution capability
     */
    constructor(string memory uri_) ERC1155(uri_) {}

    /**
     * @dev Set the issuer address (only callable by the owner)
     * @param _issuer Address of the issuer
     */
    function setIssuer(address _issuer) external onlyOwner {
        s_issuer = _issuer;
        emit SetIssuer(_issuer);
    }

    /**
     * @dev Mint a single token type
     * @param _to Recipient address
     * @param _id Token ID to mint
     * @param _amount Quantity of tokens to mint
     * @param _data Additional data with no specified format
     * @param _tokenUri URI specific to the token ID
     */
    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data, string memory _tokenUri)
        public
        onlyIssuerOrItself
    {
        _mint(_to, _id, _amount, _data);
        _tokenURIs[_id] = _tokenUri; // Store the token-specific URI
    }

    /**
     * @dev Mint multiple token types in a batch
     * @param _to Recipient address
     * @param _ids Array of token IDs
     * @param _amounts Array of token quantities
     * @param _data Additional data with no specified format
     * @param _tokenUris Array of URIs for each token ID
     */
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data,
        string[] memory _tokenUris
    ) public onlyIssuerOrItself {
        _mintBatch(_to, _ids, _amounts, _data);
        for (uint256 i = 0; i < _ids.length; ++i) {
            _tokenURIs[_ids[i]] = _tokenUris[i]; // Store each token URI
        }
    }

    /**
     * @dev Burn a specific amount of a single token type
     * @param account Address of the token holder
     * @param id Token ID to burn
     * @param amount Quantity of tokens to burn
     */
    function burn(address account, uint256 id, uint256 amount) public onlyIssuerOrItself {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }
        _burn(account, id, amount);
    }

    /**
     * @dev Burn multiple token types in a batch
     * @param account Address of the token holder
     * @param ids Array of token IDs to burn
     * @param amounts Array of quantities to burn for each token ID
     */
    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public onlyIssuerOrItself {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }
        _burnBatch(account, ids, amounts);
    }

    /**
     * @dev Returns the URI for a given token ID
     * @param tokenId Token ID to query
     * @return The URI string for the token ID
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];
        return bytes(tokenURI).length > 0 ? tokenURI : super.uri(tokenId);
    }

    /**
     * @dev Internal function to set a token-specific URI
     * @param tokenId Token ID to set URI for
     * @param tokenURI The URI string to assign
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }
}
