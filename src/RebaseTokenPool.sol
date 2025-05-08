// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.24 <0.9.0;

import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {Pool} from "@ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";
import {IPoolV1} from "@ccip/contracts/src/v0.8/ccip/interfaces/IPool.sol"; // Explicit import for clarity
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol"; // Use version compatible with CCIP contracts
import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract RebaseTokenPool is TokenPool {
    constructor(address _token, address[] memory _allowlist, address _rmnProxy, address _router) TokenPool(IERC20(_token), _allowlist, _rmnProxy, _router){}
    /**
     * @notice Called by the CCIP Router when initiating a cross-chain transfer FROM this chain.
     * Burns tokens locally and prepares data (including interest rate) for the destination chain.
     */
    function lockOrBurn(Pool.LockOrBurnInV1 calldata lockOrBurnIn) 
        external 
        override 
        returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut){
            // 1.Perform essential security checks for the base
            _validateLockOrBurn(lockOrBurnIn);
            // 2. Earn an original sender`s address
            address originalSender = lockOrBurnIn.originalSender;
            // 3. Get the user's current interest rate from the Rebasing Token contract
            // We need to cast the stored IERC20 token address (i_token) to our custom interface
            // Requires intermediate cast to address
            IRebaseToken rebaseToken = IRebaseToken(address(i_token));
            uint256 userInterestRate = rebaseToken.getUserInterestRate(originalSender);

            // 4. Burn the specified amount of tokens FROM THE POOL'S BALANCE
            // IMPORTANT: CCIP transfers tokens *to* the pool *before* calling lockOrBurn.
            // The pool must burn tokens it now holds.
            rebaseToken.burn(address(this), lockOrBurnIn.amount);
            lockOrBurnOut = Pool.LockOrBurnOutV1({
                destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector),
                destPoolData: abi.encode(userInterestRate)
            });
            // Implicit return because `lockOrBurnOut` is assigned.
    }

    /**
     * @notice Called by the CCIP Router when finalizing a cross-chain transfer TO this chain.
     * Decodes interest rate from source chain data and mints tokens to the receiver.
     */
    function releaseOrMint(Pool.ReleaseOrMintInV1 calldata releaseOrMintIn) 
        external 
        override 
        returns (Pool.ReleaseOrMintOutV1 memory releaseOrMintOut) {
        // 1. Perform essential security checks for the base 
        _validateReleaseOrMint(releaseOrMintIn);
        uint256 userInterestRate = abi.decode(releaseOrMintIn.sourcePoolData, (uint256));
        IRebaseToken rebaseToken = IRebaseToken(address(i_token));
        rebaseToken.mint(releaseOrMintIn.receiver, releaseOrMintIn.amount, userInterestRate);
        return Pool.ReleaseOrMintOutV1({
            destinationAmount: releaseOrMintIn.amount
        });
    }
}