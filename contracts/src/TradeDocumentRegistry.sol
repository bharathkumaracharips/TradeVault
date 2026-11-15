// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITradeDocumentRegistry} from "./interfaces/ITradeEscrowVault.sol";

contract TradeDocumentRegistry is ITradeDocumentRegistry {
    mapping(bytes32 => mapping(bytes32 => DocumentRecord)) private _documents;

    function commitDocument(
        bytes32 tradeId,
        bytes32 docHash,
        DocumentType docType,
        string calldata ipfsCID
    ) external override {
        require(docHash != bytes32(0), "Empty docHash");

        _documents[tradeId][docHash] = DocumentRecord({
            docHash: docHash,
            ipfsCID: ipfsCID,
            docType: docType,
            uploadedBy: msg.sender,
            uploadedAt: uint64(block.timestamp)
        });

        emit DocumentCommitted(tradeId, docHash, docType, ipfsCID);
    }

    function getDocument(bytes32 tradeId, bytes32 docHash) external view override returns (DocumentRecord memory) {
        DocumentRecord memory doc = _documents[tradeId][docHash];
        require(doc.uploadedAt != 0, "Document not found");
        return doc;
    }
}
