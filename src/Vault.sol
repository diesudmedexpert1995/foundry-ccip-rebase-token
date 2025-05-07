// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.24 <0.9.0;
import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    error Vault__RedeemFailed();
    
    IRebaseToken private immutable i_rebaseToken;
    // Event emitted when tokens are deposited into the vault
    event Deposit(address indexed user, uint256 amount);
    // Event emitted when tokens are redeemed from the vault
    event Redeem(address indexed user, uint256 amount);

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    /**
     * @notice Allows the contract to receive plain ETH transfers (e.g., for rewards).
    */
   receive() external payable {}

    /**
     * @notice Allows users to deposit tokens into the vault and receive an equivalent amount of RebaseToken
     * @dev Mints token based on msg.value sent with the transaction
    */
    function deposit() external payable {
        uint256 amountToMint = msg.value;
        if(amountToMint == 0){
            revert("Deposit amount must be greater than 0");
        }
        i_rebaseToken.mint(msg.sender, amountToMint);
        emit Deposit(msg.sender, amountToMint);
    }

    /**
     * @notice Allows users to burn their RebaseTokens and receive the equivalent amount of ETH.
     * @param _amount The amount of RebaseTokens to burn and redeem for ETH.
    */
    function redeem(uint256 _amount) external {
        if(_amount == 0){
            revert("Redeem amount must be greater than 0");
        }
        if(_amount == type(uint256).max){
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        i_rebaseToken.burn(msg.sender, _amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if(!success){
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    // Public getter for the RebaseToken address
    /**
     * @notice Returns the address of the RebaseToken contract this vault interacts with.
     * @return address The address of the RebaseToken contract.
    */
    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}