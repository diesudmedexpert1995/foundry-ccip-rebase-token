// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.24 < 0.9.0;

/**
 * @title IRebaseToken Interface
 * @notice Defines the functions the Vault contract needs to call on the RebaseToken contract.
 */
interface IRebaseToken {
    /**
     * @notice Mints new tokens to a specified address.
     * @param _to The address to receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @param _userInterestRate The interest rate for the user
     */
    function mint(address _to, uint256 _amount, uint256 _userInterestRate) external;
    /**
     * @notice Burns tokens from a specified address.
     * @param _from The address whose tokens will be burned.
     * @param _amount The amount of tokens to burn.
     */
    function burn(address _from, uint256 _amount) external;
    
    /**
     * @notice Return the balance of a specified address.
     * @param _user The address whose tokens will be burned.
     * @return The balance of the specified address.
     */
    function balanceOf(address _user) external view returns (uint256);

     /**
     * @notice Return the interest rate value of a specified address.
     * @param _account The address whose tokens will be burned.
     * @return The interest value of the specified address.
     */
    
    function getUserInterestRate(address _account) external view returns (uint256);

    /**
     * @notice Return the interest rate value     
     * @return The interest value.
     */
    
    function getInterestRate() external view returns (uint256);

    /**
     * @notice Grants role to mint and burn
     */
    function grantMintAndBurnRole(address _account) external;
}