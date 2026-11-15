// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ParticipantRegistry} from "../src/ParticipantRegistry.sol";
import {TradeAgreementManager} from "../src/TradeAgreementManager.sol";
import {TradeEscrowVault} from "../src/TradeEscrowVault.sol";
import {TradeDocumentRegistry} from "../src/TradeDocumentRegistry.sol";
import {AttestationIssuerRegistry} from "../src/AttestationIssuerRegistry.sol";
import {MilestoneManager} from "../src/MilestoneManager.sol";
import {TradeDisputeManager} from "../src/TradeDisputeManager.sol";

contract DeployScript {
    struct DeploymentResult {
        address participantRegistry;
        address agreementManager;
        address escrowVault;
        address documentRegistry;
        address issuerRegistry;
        address milestoneManager;
        address disputeManager;
    }

    function run() external returns (DeploymentResult memory result) {
        address deployer = msg.sender;

        ParticipantRegistry participantReg = new ParticipantRegistry(deployer);
        TradeAgreementManager agreementMgr = new TradeAgreementManager(deployer);
        TradeEscrowVault escrowVault = new TradeEscrowVault(address(0), address(0));
        TradeDocumentRegistry docReg = new TradeDocumentRegistry();
        AttestationIssuerRegistry issuerReg = new AttestationIssuerRegistry(deployer);

        MilestoneManager milestoneMgr = new MilestoneManager(address(agreementMgr), address(escrowVault));
        TradeDisputeManager disputeMgr = new TradeDisputeManager(address(agreementMgr), address(escrowVault), deployer);

        escrowVault.setManagers(address(milestoneMgr), address(disputeMgr));

        result = DeploymentResult({
            participantRegistry: address(participantReg),
            agreementManager: address(agreementMgr),
            escrowVault: address(escrowVault),
            documentRegistry: address(docReg),
            issuerRegistry: address(issuerReg),
            milestoneManager: address(milestoneMgr),
            disputeManager: address(disputeMgr)
        });
    }
}
