// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Importing core ERC1155 functionality and custom ERC1155Core contract
import {ERC1155Core, ERC1155} from "./ERC1155Core.sol";
// Chainlink CCIP libraries and interfaces for cross-chain communication
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
// Chainlink LINK token interface
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
// Security module to prevent re-entrancy attacks
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// Custom utility for withdrawal functionality
import {Withdraw} from "./utils/Withdraw.sol";

/**
 * @title CrossChainBurnAndMintERC1155
 * @dev ERC1155 token contract enabling cross-chain transfers using Chainlink CCIP.
 *      The contract burns tokens on the source chain and mints them on the destination chain.
 */
contract CrossChainBurnAndMintERC1155 is ERC1155Core, IAny2EVMMessageReceiver, ReentrancyGuard, Withdraw {
    // Enumeration to specify fee payment in native currency or LINK
    enum PayFeesIn {
        Native,
        LINK
    }

    // Custom errors for better gas efficiency
    error InvalidRouter(address router);
    error NotEnoughBalanceForFees(uint256 currentBalance, uint256 calculatedFees);
    error ChainNotEnabled(uint64 chainSelector);
    error SenderNotEnabled(address sender);
    error OperationNotAllowedOnCurrentChain(uint64 chainSelector);

    // Struct for storing details about cross-chain NFT counterparts
    struct XNftDetails {
        address xNftAddress;
        bytes ccipExtraArgsBytes;
    }

    // Immutable references to essential components
    IRouterClient internal immutable i_ccipRouter;
    LinkTokenInterface internal immutable i_linkToken;
    uint64 private immutable i_currentChainSelector;

    // Mapping of chain selectors to their cross-chain NFT details
    mapping(uint64 destChainSelector => XNftDetails xNftDetailsPerChain) public s_chains;

    // Events for tracking chain status and cross-chain token transfers
    event ChainEnabled(uint64 chainSelector, address xNftAddress, bytes ccipExtraArgs);
    event ChainDisabled(uint64 chainSelector);
    event CrossChainSent(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes data,
        uint64 sourceChainSelector,
        uint64 destinationChainSelector
    );
    event CrossChainReceived(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes data,
        uint64 sourceChainSelector,
        uint64 destinationChainSelector
    );

    // Modifier to ensure only the CCIP router can call certain functions
    modifier onlyRouter() {
        if (msg.sender != address(i_ccipRouter)) revert InvalidRouter(msg.sender);
        _;
    }

    // Modifier to ensure the chain is enabled for cross-chain operations
    modifier onlyEnabledChain(uint64 _chainSelector) {
        if (s_chains[_chainSelector].xNftAddress == address(0)) revert ChainNotEnabled(_chainSelector);
        _;
    }

    // Modifier to ensure the sender is authorized
    modifier onlyEnabledSender(uint64 _chainSelector, address _sender) {
        if (s_chains[_chainSelector].xNftAddress != _sender) revert SenderNotEnabled(_sender);
        _;
    }

    // Modifier to prevent operations on the same chain
    modifier onlyOtherChains(uint64 _chainSelector) {
        if (_chainSelector == i_currentChainSelector) revert OperationNotAllowedOnCurrentChain(_chainSelector);
        _;
    }

    /**
     * @dev Constructor sets initial configuration
     * @param uri_ Base URI for tokens
     * @param ccipRouterAddress Address of the CCIP router
     * @param linkTokenAddress Address of the LINK token
     * @param currentChainSelector Selector for the current chain
     */
    constructor(string memory uri_, address ccipRouterAddress, address linkTokenAddress, uint64 currentChainSelector)
        ERC1155Core(uri_)
    {
        i_ccipRouter = IRouterClient(ccipRouterAddress);
        i_linkToken = LinkTokenInterface(linkTokenAddress);
        i_currentChainSelector = currentChainSelector;
    }

    /**
     * @dev Enable a chain for cross-chain transfers
     */
    function enableChain(uint64 chainSelector, address xNftAddress, bytes memory ccipExtraArgs)
        external
        onlyOwner
        onlyOtherChains(chainSelector)
    {
        s_chains[chainSelector] = XNftDetails({xNftAddress: xNftAddress, ccipExtraArgsBytes: ccipExtraArgs});
        emit ChainEnabled(chainSelector, xNftAddress, ccipExtraArgs);
    }

    /**
     * @dev Disable a chain, preventing further cross-chain operations
     */
    function disableChain(uint64 chainSelector) external onlyOwner onlyOtherChains(chainSelector) {
        delete s_chains[chainSelector];
        emit ChainDisabled(chainSelector);
    }

    /**
     * @dev Initiates a cross-chain transfer by burning tokens on the source chain
     */
    function crossChainTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data,
        uint64 destinationChainSelector,
        PayFeesIn payFeesIn
    ) external nonReentrant onlyEnabledChain(destinationChainSelector) returns (bytes32 messageId) {
        string memory tokenUri = uri(id);
        burn(from, id, amount);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(s_chains[destinationChainSelector].xNftAddress),
            data: abi.encode(from, to, id, amount, data, tokenUri),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: s_chains[destinationChainSelector].ccipExtraArgsBytes,
            feeToken: payFeesIn == PayFeesIn.LINK ? address(i_linkToken) : address(0)
        });

        uint256 fees = i_ccipRouter.getFee(destinationChainSelector, message);

        if (payFeesIn == PayFeesIn.LINK) {
            if (fees > i_linkToken.balanceOf(address(this))) {
                revert NotEnoughBalanceForFees(i_linkToken.balanceOf(address(this)), fees);
            }
            i_linkToken.approve(address(i_ccipRouter), fees);
            messageId = i_ccipRouter.ccipSend(destinationChainSelector, message);
        } else {
            if (fees > address(this).balance) revert NotEnoughBalanceForFees(address(this).balance, fees);
            messageId = i_ccipRouter.ccipSend{value: fees}(destinationChainSelector, message);
        }

        emit CrossChainSent(from, to, id, amount, data, i_currentChainSelector, destinationChainSelector);
    }
    
    /**
     * @notice Checks if the contract supports a given interface.
     * @dev Overrides the ERC1155 supportsInterface function to include support for
     *      the IAny2EVMMessageReceiver interface required for Chainlink CCIP cross-chain messaging.
     *      This allows external contracts, tools, and protocols to detect that this contract
     *      can handle cross-chain messages in addition to standard ERC1155 functionality.
     * @param interfaceId The interface identifier, as specified in ERC-165.
     * @return True if the contract implements the specified interface, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155) returns (bool) {
        return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Receives CCIP messages and mints corresponding tokens
     */
    function ccipReceive(Client.Any2EVMMessage calldata message)
        external
        override
        onlyRouter
        nonReentrant
        onlyEnabledChain(message.sourceChainSelector)
        onlyEnabledSender(message.sourceChainSelector, abi.decode(message.sender, (address)))
    {
        uint64 sourceChainSelector = message.sourceChainSelector;
        (address from, address to, uint256 id, uint256 amount, bytes memory data, string memory tokenUri) =
            abi.decode(message.data, (address, address, uint256, uint256, bytes, string));

        mint(to, id, amount, data, tokenUri);
        emit CrossChainReceived(from, to, id, amount, data, sourceChainSelector, i_currentChainSelector);
    }
}
