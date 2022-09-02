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
    string constant INVALID_SIGN = "Invalid signature";

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

    /**
     * A  all can mint token,but a can be trigger or accepter
     */
    function mint(
        address _to,
        string calldata _uri,
        uint256 _expirationDate,
        bytes calldata _signature
    ) external onlyOwner() payable returns (uint256) {
        require(_to != address(0), ZERO_ADDRESS);
        require(_verify(_hash(nonce), _signature, _to), INVALID_SIGN);
        uint256 tokenId = tokens.length;
        super._mint(_to, tokenId);
        super._setTokenURI(tokenId, _uri);
        super._setExpirationdate(tokenId, _expirationDate);
        emit Issued(sbt_tokenIssuer, _to, tokenId, _expirationDate);
        return tokenId;
    }

    function burn(
        uint256 _tokenId
    ) external payable {
        super._burn(_tokenId);
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

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Withdraw failed.");
    }

    fallback() external payable {}

    receive() external payable {}

    
    
}