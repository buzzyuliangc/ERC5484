// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../tokens/soul-token.sol";
import "../ownership/ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract Solpass is Soul_Token {

    // Resolver public defaultResolver;

    constructor(BurnAuth _burnAuth, string memory _nftName, string memory _nftSymbol, string memory _baseURI) Soul_Token(_burnAuth){
        nftName = _nftName;
        nftSymbol = _nftSymbol;
        _setBaseURI(_baseURI);
    }

    using ECDSA for bytes32;
    string private nonce = "i will";
    string private burnNonce = "fine";
    string constant NOT_ENOUGH_ETH = "not enough eth";
    string constant INVALID_SIGN = "Invalid signature";

    uint256 private constant priceStep = 0.005 * (10**18);
    uint256 private constant priceMin = 0.01 * (10**18);
    uint256 private priceMax = 0.05 * (10**18);

    bytes32 private merkleRoot;

    function isWhiteList(address _address, bytes32[] calldata _merkleProof)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            return true;
        }
        return false; // Or you can mint tokens here
    }

    function setMercleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getPrice() external view returns (uint256) {
        return _getPrice();
    }

    function getPriceByProof(bytes32[] calldata _merkleProof)
        external
        view
        returns (uint256)
    {
        if (isWhiteList(tx.origin, _merkleProof)) {
            return 0;
        } else {
            return _getPrice();
        }
    }

    /**
     * A  all can mint token,but a can be trigger or accepter
     */
    function mint(
        address _to,
        string calldata _uri,
        uint256 _expirationDate,
        bytes calldata _signature,
        bytes32[] calldata _merkleProof
    ) external onlyOwner() payable returns (uint256) {
        if (!isWhiteList(tx.origin, _merkleProof)) {
            require(_getPrice() <= msg.value, NOT_ENOUGH_ETH);
        }
        require(_to != address(0), ZERO_ADDRESS);
        require(_verify(_hash(nonce), _signature, _to), INVALID_SIGN);
        uint256 tokenId = tokens.length;
        super._mint(_to, tokenId);
        super._setTokenURI(tokenId, _uri);
        super._setExpirationdate(tokenId, _expirationDate);
        emit Issued(sbt_tokenIssuer, _to, tokenId, _expirationDate);
        return tokenId;
    }

    /**
     * A  all can mint token,but a can be trigger or accepter
     */
    /*function mintTest(
        address _to,
        string calldata _uri,
        uint256 _expirationDate
    ) external onlyOwner() payable returns (uint256){
        require(_to != address(0), ZERO_ADDRESS);
        uint256 tokenId = tokens.length;
        super._mint(_to, tokenId);
        super._setTokenURI(tokenId, _uri);
        super._setExpirationdate(tokenId, _expirationDate);
        emit Issued(sbt_tokenIssuer, _to, tokenId, _expirationDate);
        return tokenId;
    }*/

    function burn(
        uint256 _tokenId,
        bytes32[] calldata _merkleProof
    ) external payable {
        if (!isWhiteList(tx.origin, _merkleProof)) {
            require(_getPrice() * 2 <= msg.value, NOT_ENOUGH_ETH);
        }
        super._burn(_tokenId);
    }

    /*function burnTest(
        uint256 _tokenId
    ) external payable {
        super._burn(_tokenId);
    }*/

    function _getPrice() private view returns (uint256) {
        uint256 n = 0;
        uint256 c = 100;
        uint256 count =  tokens.length / 2;
        while (count >= c && n <= 9) {
            n++;
            c = c + (n + 1) * 100;
        }
        uint256 price = priceMin + priceStep * n;
        return price <= priceMax ? price : priceMax;
    }

    function _hash(string memory hash) private pure returns (bytes32) {
        return keccak256(abi.encode(hash));
    }

    function _verify(
        bytes32 hash,
        bytes memory _token,
        address _signer
    ) private pure returns (bool) {
        return (_recover(hash, _token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory _token)
        private
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(_token);
    }

    function updateNonce(string memory _nonce) external onlyOwner {
        nonce = _nonce;
    }

    function updateBurnNonce(string memory _nonce) external onlyOwner {
        burnNonce = _nonce;
    }

    function updatePriceMax(uint256 _priceMax) external onlyOwner {
        priceMax = _priceMax;
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Withdraw failed.");
    }

    fallback() external payable {}

    receive() external payable {}

    
    
}