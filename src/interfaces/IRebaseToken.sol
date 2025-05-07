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
     */
    function mint(address _to, uint256 _amount) external;
    /**
     * @notice Burns tokens from a specified address.
     * @param _from The address whose tokens will be burned.
     * @param _amount The amount of tokens to burn.
     */
    function burn(address _from, uint256 _amount) external;
    
    /**
     * @notice Return the balance of a specified address.
     * @param _user The address whose tokens will be burned.
     * @return The balance of the specifoed address.
     */
    function balanceOf(address _user) external view returns (uint256);
}