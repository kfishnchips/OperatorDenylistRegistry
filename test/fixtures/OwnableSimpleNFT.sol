// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {IOperatorDenylistRegistry} from "../../src/interfaces/IOperatorDenylistRegistry.sol";

contract OwnableSimpleNFT is ERC721, Ownable {
    error OperatorDenied();
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    IOperatorDenylistRegistry public operatorDenylistRegistry;

    constructor(address _operatorDenylistRegistry) ERC721("OwnableSimpleNFT", "OSNFT") {
        operatorDenylistRegistry = IOperatorDenylistRegistry(_operatorDenylistRegistry);
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
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
