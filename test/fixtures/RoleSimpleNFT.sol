// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {IOperatorDenylistRegistry} from "../../src/interfaces/IOperatorDenylistRegistry.sol";

contract RoleSimpleNFT is ERC721, AccessControl {
    error OperatorDenied();

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    IOperatorDenylistRegistry operatorDenylistRegistry;

    constructor(address _operatorDenylistRegistry) ERC721("RoleSimpleNFT", "RSNFT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        operatorDenylistRegistry = IOperatorDenylistRegistry(_operatorDenylistRegistry);
    }

    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        if(operatorDenylistRegistry.isOperatorDenied(msg.sender)) revert OperatorDenied();
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}
