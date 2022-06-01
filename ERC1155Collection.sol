// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// OpenZeppelin Contracts
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ERC2981/ERC2981PerTokenUpgradeable.sol";

contract ERC1155Collection is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ERC2981PerTokenUpgradeable {

    struct Meta {
        string name;
        string symbol;
        string description;
    }

    Meta public data;

    uint256 public immutable tokenSupply = 808; // fungible token maximum supply
    uint256 public immutable collectionSupply = 202; // collection maximum supply

    mapping (uint256 => address) private _existId; // If token exist => address(creator)
    mapping (uint256 => string) private _tokenURIs; // Mapping Ids to corresponding URIs
    mapping (string => uint256) private _existURI; // Exist uri check

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _tokenIds; // Amount of all minted tokens || default = 0

    // Events
    event Mint(uint256 tokenId, address recipient, uint256 amount);

    constructor() initializer {}

    function initialize (Meta memory _data, address _owner)
    external initializer
    {
        __ERC1155_init("");
        __Ownable_init();
        transferOwnership(_owner);

        data.name = _data.name;
        data.symbol = _data.symbol;
        data.description = _data.description;
    }

    // Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155Upgradeable, IERC165Upgradeable)
    returns (bool)
    {
        return interfaceId == type(IERC2981Upgradeable).interfaceId ||
        super.supportsInterface(interfaceId);
    }


    // MINTING
    //  mint one token with specified amount
    //  if amount > 1 : fungible, else : non-fungible
    function mint(
        address to,
        string memory tokenURI,
        uint256 amount,
        address royaltyRecipient,
        uint256 royaltyValue
    )
    external onlyOwner returns(uint256) {

        // Supply check
        require((_tokenIds.current() + 1) <= collectionSupply, "All tokens are minted");
        require(amount >= 1 && amount <= tokenSupply, "Max token supply: 808 samples");

        // Uri check
        require(_existURI[tokenURI] != 1, "Token with given URI already exists, consider using mintMore()");
        require(bytes(tokenURI).length > 0, "URI can not be empty");

        // Royalty check
        require(royaltyRecipient != address(0), "Royalty recipients address is equal to 0");
        require(royaltyValue <= 1100, "Royalty fee should be <= 11.00");

        _tokenIds.increment(); // Increment first to start from 1
        uint256 newItemId = _tokenIds.current();

        _mint(to, newItemId, amount, "");
        _setTokenUri(newItemId, tokenURI);
        _existId[newItemId] = to;

        // Set royalty fee for the token
        if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue);
        }

        emit Mint(newItemId, to, amount);
        return newItemId;
    }

    // Mint multiple tokens with specified amounts
    function mintBatch(
        address to,
        string[] memory tokenURIs,
        uint256[] memory amounts,
        address[] memory royaltyRecipients,
        uint256[] memory royaltyValues
    )
    external onlyOwner returns(uint256[] memory){

        // Can't exceed collection's max token supply
        require((_tokenIds.current() + tokenURIs.length) <= collectionSupply, "All tokens are minted");

        // All arrays should be equal
        require(
            tokenURIs.length == amounts.length &&
            amounts.length == royaltyRecipients.length &&
            royaltyRecipients.length == royaltyValues.length,
            "Arrays length mismatch");

        // Checking values
        for(uint256 i = 0; i < tokenURIs.length; i++) {
            require(bytes(tokenURIs[i]).length > 0, "URI can not be empty");
            require(amounts[i] >= 1 && amounts[i] <= tokenSupply, "Max token supply: 808 samples");
            require(_existURI[tokenURIs[i]] == 0, "Token with given URI already exists, consider using mintMore()");
            require(royaltyRecipients[i] != address(0), "Royalty recipients address is equal to 0");
            require(royaltyValues[i] <= 1100, "Royalty fee should be <= 11.00");
        }

        // New ids
        uint256[] memory newItemsIds = new uint256[](amounts.length);

        for(uint256 i = 0; i < amounts.length; i++){

            // Set current id
            _tokenIds.increment();
            newItemsIds[i] = _tokenIds.current();

            _setTokenUri(newItemsIds[i], tokenURIs[i]);
            _existId[newItemsIds[i]] = to;

            // Set royalty fee for tokens
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(newItemsIds[i], royaltyRecipients[i], royaltyValues[i]);
            }

            emit Mint(newItemsIds[i], to, amounts[i]);
        }

        _mintBatch(to, newItemsIds, amounts, "");

        return (newItemsIds);
    }

    // Mint more tokens with existing id
    function mintMore(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {

        require((balanceOf(to, tokenId)) > 1, "Can't mint more tokens of non-fungible");
        require((balanceOf(to, tokenId) + amount) <= tokenSupply, "Max token supply: 808 samples");
        require(tokenId > 0 && _existId[tokenId] != address(0), "Token doesn't exist");

        _mint(to, tokenId, amount, "");
        emit Mint(tokenId, to, amount);
    }

    // Overrides of ERC1155
    function uri(uint256 tokenId) override public view returns (string memory) {
        return(_tokenURIs[tokenId]);
    }

    // Push tokenURI to array with corresponding tokenId
    function _setTokenUri(uint256 tokenId, string memory tokenURI) private {
        _tokenURIs[tokenId] = tokenURI;
        _existURI[tokenURI] = tokenId;
    }

    // Get address by Id
    function getExistId(uint256 tokenId) external view returns(address) {

        require(_existId[tokenId] != address(0) && tokenId != 0, "Provided tokenId doesn't exist");
        return _existId[tokenId];
    }
}
