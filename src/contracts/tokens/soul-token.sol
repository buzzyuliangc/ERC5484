// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../tokens/erc42.sol";
import "../tokens/nf-token.sol";
import "../ownership/ownable.sol";
import "../tokens/erc721-enumerable.sol";
import "../tokens/erc721-metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Soul_Token is NFToken, ERC42, Ownable, ERC721Enumerable, ERC721Metadata {
    using Strings for uint256; 
    
    event Minted(address indexed issuer, address indexed owner, uint256 indexed tokenId);
    event Burned(address indexed issuer, address indexed owner, address operator, uint256 indexed tokenId);

    
    
    /**
     * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
     * Based on 0xcert framework error codes.
     */
    string constant INVALID_INDEX = "005007";
    string constant BURN_ACCESS_DENIED = "006000";

    /**
    * @dev A descriptive name for a collection of NFTs.
    */
    string internal nftName;

    /**
    * @dev An abbreviated name for NFTokens.
    */
    string internal nftSymbol;

    // Base URI
    string internal baseURI;

    /**
     * @dev burn authority of the collection
     */
    BurnAuth internal sbt_burnAuth;

    /**
     * @dev Array of all NFT IDs.
     */
    uint256[] internal tokens;

    address internal sbt_tokenIssuer;

    /**
     * @dev Mapping from token ID to its expiration Date.
     */
    mapping (uint256 => uint256) internal idToExpiration;

    /**
    * @dev Mapping from NFT ID to metadata uri.
    */
    mapping (uint256 => string) internal idToURI;

    /**
     * @dev Mapping from token ID to its index in global tokens array.
     */
    mapping(uint256 => uint256) internal idToIndex;

    /**
     * @dev Mapping from owner to list of owned NFT IDs.
     */
    mapping(address => uint256[]) internal ownerToIds;

    /**
     * @dev Mapping from NFT ID to its index in the owner tokens list.
     */
    mapping(uint256 => uint256) internal idToOwnerIndex;

    /**
     * @dev Guarantees that the msg.sender is allowed to transfer NFT.
     * @param _tokenId ID of the NFT to transfer.
     */
    modifier burnable(uint256 _tokenId) {
        require(sbt_burnAuth!= BurnAuth.Neither, BURN_ACCESS_DENIED);
        address tokenOwner = idToOwner[_tokenId];
        if (sbt_burnAuth == BurnAuth.IssuerOnly) {
            require(sbt_tokenIssuer == msg.sender, BURN_ACCESS_DENIED);
        }
        else if (sbt_burnAuth == BurnAuth.OwnerOnly) {
            require(
                tokenOwner == msg.sender ||
                idToApproval[_tokenId] == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
                BURN_ACCESS_DENIED
            );
        }
        else if (sbt_burnAuth == BurnAuth.Both) {
             require(
                sbt_tokenIssuer == msg.sender ||
                tokenOwner == msg.sender ||
                idToApproval[_tokenId] == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
                BURN_ACCESS_DENIED
            );           
        }
        _;
    }

    constructor(BurnAuth _burnAuth)
    {
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
        sbt_tokenIssuer = msg.sender;
        sbt_burnAuth = _burnAuth;
    }

    /**
    * @dev Returns a descriptive name for a collection of NFTokens.
    * @return _name Representing name.
    */
    function name()
        external
        override
        view
        returns (string memory _name)
    {
        _name = nftName;
    }

    /**
    * @dev Returns an abbreviated name for NFTokens.
    * @return _symbol Representing symbol.
    */
    function symbol()
        external
        override
        view
        returns (string memory _symbol)
    {
        _symbol = nftSymbol;
    }

    /**
    * @dev Returns the Issuer address for the sbt collection.
    * @return _tokenIssuer of _tokenId.
    */
    function tokenIssuer()
        external
        override
        view
        returns (address _tokenIssuer)
    {
        _tokenIssuer = sbt_tokenIssuer;
    }

    /**
    * @dev A distinct URI (RFC 3986) for a given NFT.
    * @param _tokenId Id for which we want uri.
    * @return URI of _tokenId.
    */
    function tokenURI(
        uint256 _tokenId
    )
        external
        override
        view
        validNFToken(_tokenId)
        returns (string memory)
    {
        return _tokenURI(_tokenId);
    }

    /**
    * @notice This is an internal function that can be overriden if you want to implement a different
    * way to generate token URI.
    * @param _tokenId Id for which we want uri.
    * @return URI of _tokenId.
    */
    function _tokenURI(
        uint256 _tokenId
    )
        internal
        virtual
        view
        validNFToken(_tokenId)
        returns (string memory)
    {
        string memory tailURI = idToURI[_tokenId];
        string memory base = baseURI;
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return tailURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(tailURI).length > 0) {
            return string(abi.encodePacked(base, tailURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, _tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function tokenBaseURI() public view virtual returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory _baseURI) internal  {
        baseURI = _baseURI;
    }

    function setBaseURI(string calldata _baseURI) public onlyOwner{
        baseURI = _baseURI;
    }

    /**
    * @notice This is an internal function which should be called from user-implemented external
    * function. Its purpose is to show and properly initialize data structures when using this
    * implementation.
    * @dev Set a distinct URI (RFC 3986) for a given NFT ID.
    * @param _tokenId Id for which we want URI.
    * @param _uri String representing RFC 3986 URI.
    */
    function _setTokenURI(
        uint256 _tokenId,
        string memory _uri
    )
        internal
        validNFToken(_tokenId)
    {
        idToURI[_tokenId] = _uri;
    }

    function setTokenURI(
        uint256 _tokenId,
        string calldata _uri
    )
        public 
        onlyOwner
        validNFToken(_tokenId)
    {
        idToURI[_tokenId] = _uri;
    }

    /**
     * @dev Returns the count of all existing NFTokens.
     * @return Total supply of NFTs.
     */
    function totalSupply() external view override returns (uint256) {
        return tokens.length;
    }

    /**
     * @dev Returns NFT ID by its index.
     * @param _index A counter less than `totalSupply()`.
     * @return Token id.
     */
    function tokenByIndex(uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        require(_index < tokens.length, INVALID_INDEX);
        return tokens[_index];
    }

    /**
     * @dev returns the n-th NFT ID from a list of owner's tokens.
     * @param _owner Token owner's address.
     * @param _index Index number representing n-th token in owner's list of tokens.
     * @return Token id.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        require(_index < ownerToIds[_owner].length, INVALID_INDEX);
        return ownerToIds[_owner][_index];
    }

    /**
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @dev Removes a NFT from an address.
     * @param _from Address from wich we want to remove the NFT.
     * @param _tokenId Which NFT we want to remove.
     */
    function _removeNFToken(address _from, uint256 _tokenId)
        internal
        virtual
        override
    {
        require(idToOwner[_tokenId] == _from, NOT_OWNER);
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }

    /**
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @dev Assigns a new NFT to an address.
     * @param _to Address to wich we want to add the NFT.
     * @param _tokenId Which NFT we want to add.
     */
    function _addNFToken(address _to, uint256 _tokenId)
        internal
        virtual
        override
    {
        require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
        idToOwner[_tokenId] = _to;

        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
    }

    /**
     * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
     * extension to remove double storage(gas optimization) of owner NFT count.
     * @param _owner Address for whom to query the count.
     * @return Number of _owner NFTs.
     */
    function _getOwnerNFTCount(address _owner)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return ownerToIds[_owner].length;
    }

    /**
     * @dev getter for getting the burn authroity of the contract. 
     * easier to mitigate unnecessary calls for 3rd party callers to burn tokens.
     * @return _burnAuth the enum of burn auth.
     */    
    function tokenBurnAuth()
        external
        view
        override
        returns (BurnAuth)
    {
        return sbt_burnAuth;
    }

    /**
     * @dev external getter for getting the expiration date of the contract. 
     * @param _tokenId for the token
     * for 3rd parties to check expirationDate of the nft
     * @return the expiration date for _tokenId.
     */    
    function expirationDate(uint256 _tokenId)
        external
        override
        view
        validNFToken(_tokenId)
        returns (uint256)
    {
        return _expirationDate(_tokenId);
    }

    /**
    * @notice This is an internal function that can be overriden if you want to implement a different
    * way to get token expiration.
    * @param _tokenId Id for which we want exp date.
    * @return exp date of _tokenId.
    */
    function _expirationDate(uint256 _tokenId)
        internal
        virtual
        view
        validNFToken(_tokenId)
        returns (uint256)
    {
        return idToExpiration[_tokenId];
    }

    /**
    * @notice This is an internal function which should be called from user-implemented external
    * function. Its purpose is to show and properly initialize data structures when using this
    * implementation.
    * @dev Set a distinct expiration date for a given NFT ID.
    * @param _tokenId Id for which we want expirationDate.
    * @param _sbtExpirationDate uint256 date for the date we want to set expiration.
    */
    function _setExpirationdate(
        uint256 _tokenId,
        uint256 _sbtExpirationDate
    )
        internal
        validNFToken(_tokenId)
    {
        idToExpiration[_tokenId] = _sbtExpirationDate;
    }

    /**
     * Only authorized contracts can be called, so this contract cannot be mint directly by users, but authorized contracts can be called by users
     */
    function _mint(
        address _to,
        uint256 _tokenId
    ) internal override virtual {
        super._mint(_to, _tokenId);
        tokens.push(_tokenId);
        idToIndex[_tokenId] = tokens.length - 1;
        emit Minted(sbt_tokenIssuer, _to, _tokenId);
    }

    /**
     * @notice This is an internal function which should be called from user-implemented external
     * burn function. Its purpose is to show and properly initialize data structures when using this
     * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
     * NFT.
     * @dev Burns a NFT.
     * @param _tokenId ID of the NFT to be burned.
     */
    function _burn(uint256 _tokenId) internal override virtual validNFToken(_tokenId) burnable(_tokenId){
        super._burn(_tokenId);
        address owner = idToOwner[_tokenId];
    
        delete idToURI[_tokenId];
        delete idToExpiration[_tokenId];

        uint256 tokenIndex = idToIndex[_tokenId];
        uint256 lastTokenIndex = tokens.length - 1;
        uint256 lastToken = tokens[lastTokenIndex];

        tokens[tokenIndex] = lastToken;

        tokens.pop();
        // This wastes gas if you are burning the last token but saves a little gas if you are not.
        idToIndex[lastToken] = tokenIndex;
        idToIndex[_tokenId] = 0;
        emit Burned(sbt_tokenIssuer, owner, msg.sender, _tokenId);
    }

    function _transfer(address _to, uint256 _tokenId) internal pure override {
        require(_to != address(0));
        require(_tokenId != 0);
        revert("cannot transfer");
    }
}