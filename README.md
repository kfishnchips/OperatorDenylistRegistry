# Operator Denylist Registry

This denylist registry can be used by anyone and is ownerless.

# Registry address

[https://etherscan.io/address/0xbD5Bf39ac08B9a16C3DE2Ad093706E70082eff8E](https://etherscan.io/address/0xbD5Bf39ac08B9a16C3DE2Ad093706E70082eff8E)

# Common addresses

* X2Y2: 0xF849de01B080aDC3A814FaBE1E2087475cF2E354
* BLUR: 0x000000000000Ad05Ccc4F10045630fb830B95127

## Usage
It is required that your contract follows either EIP173 (Ownable) or AccessControl.

This is an example contract that makes use of the registry.

```solidity
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
```

The key parts are:
1. Import `IOperatorDenylistRegistry`
2. A reference to the Denylist Registry

    `IOperatorDenylistRegistry public operatorDenylistRegistry;`

3. Set the address of the registry in your constructor

    `operatorDenylistRegistry = IOperatorDenylistRegistry(_operatorDenylistRegistry);`

4. In your before transfer hook function add the check

    `if(operatorDenylistRegistry.isOperatorDenied(msg.sender)) revert OperatorDenied();`

## Adding or removing addresses from the denylist for your contract

1. Go to the registry contract
2. Use the `setOperatorDenied` or `batchSetOperatorDenied` functions (check documentation in the contract for specifics)

## Adding or removing registry operators for your contract
Registry operators are addresses that can manage operators for your contract.

1. Go to the registry contract
2. Use the `setApprovalForRegistryOperator` or `batchSetApprovalForRegistryOperator` functions (check documentation in the contract for specifics)

A better README is coming.
