// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC4626 } from "openzeppelin/interfaces/IERC4626.sol";
import { SafeERC20, IERC20Permit } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { ERC20, IERC20, IERC20Metadata } from "openzeppelin/token/ERC20/ERC20.sol";
import { Math } from "openzeppelin/utils/math/Math.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";

import { Claimable } from "./abstract/Claimable.sol";
import { TwabERC20 } from "./TwabERC20.sol";

import { Vault } from "./Vault.sol";

/// @title  PoolTogether V5 Prize Vault
/// @author G9 Software Inc
contract PrizeVault is Vault, Claimable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    ////////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Vault constructor
    /// @param name_ Name of the ERC20 share minted by the vault
    /// @param symbol_ Symbol of the ERC20 share minted by the vault
    /// @param yieldVault_ Address of the underlying ERC4626 vault in which assets are deposited to generate yield
    /// @param prizePool_ Address of the PrizePool that computes prizes
    /// @param claimer_ Address of the claimer
    /// @param yieldFeeRecipient_ Address of the yield fee recipient
    /// @param yieldFeePercentage_ Yield fee percentage
    /// @param yieldBuffer_ Amount of yield to keep as a buffer
    /// @param owner_ Address that will gain ownership of this contract
    constructor(
        string memory name_,
        string memory symbol_,
        IERC4626 yieldVault_,
        PrizePool prizePool_,
        address claimer_,
        address yieldFeeRecipient_,
        uint32 yieldFeePercentage_,
        uint256 yieldBuffer_,
        address owner_
    ) Vault(name_, symbol_, yieldVault_, prizePool_.twabController(), yieldFeeRecipient_, yieldFeePercentage_, yieldBuffer_, owner_) Claimable(prizePool_, claimer_) {
    }

    /// @inheritdoc ILiquidationSource
    function verifyTokensIn(
        address _tokenIn,
        uint256 _amountIn,
        bytes calldata /* transferTokensOutData */
    ) external virtual override onlyLiquidationPair {
        address _prizeToken = address(prizePool.prizeToken());
        if (_tokenIn != _prizeToken) {
            revert LiquidationTokenInNotPrizeToken(_tokenIn, _prizeToken);
        }

        prizePool.contributePrizeTokens(address(this), _amountIn);
    }

    /// @inheritdoc ILiquidationSource
    function targetOf(address /* tokenIn */) external view override returns (address) {
        return address(prizePool);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Setter Functions
    ////////////////////////////////////////////////////////////////////////////////

    /// @notice Set claimer.
    /// @param _claimer Address of the claimer
    function setClaimer(address _claimer) external onlyOwner {
        _setClaimer(_claimer);
    }
}
