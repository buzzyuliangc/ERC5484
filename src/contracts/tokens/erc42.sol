// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ERC-42 Soulbound Token interface
 */
interface ERC42
{

    /**
     * @dev enum to keep track of burn authorization of the token collection
     */
    enum BurnAuth {
        IssuerOnly,
        OwnerOnly,
        Both,
        Neither
    }

    /**
     * @dev Emits when the sbt is issued. 
     * Still inherits the Transfer event of ERC721 to be complient. Exception: during contract creation, any
     * number of NFTs may be created and assigned without emitting Issue.
     */
    event Issued(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 _expirationDate
    );

    /**
     * @notice when the owner has burn Auth, owner can authorize operator to burn on his behave
     * @dev Find the burn authorization of the token collection
     * @return _burnAuth returns Burn Authority of the collection
     */
    function tokenBurnAuth()
        external
        view
        returns (BurnAuth);

    /**
     * @notice when it returns 0, it is assumed that the token never expires
     */
    function expirationDate(uint256 _tokenId)
        external
        view
        returns (uint256);

    /**
     * @return _tokenIssuer the issuer address of the token collection
     */
    function tokenIssuer()
        external
        view
        returns (address _tokenIssuer);
}