// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/*  @dev Contract for handling user compliance status for RWA tokens with customizable requirements
 */
contract EnhancedComplianceRegistry is Ownable {
    // Basic compliance verification flags
    struct UserVerificationData {
        bool ageOver18;
        bool ageOver21;
        bool ageOver55;
        bool govIDVerified;
        bool addressVerified;
        bool accreditedInvestor;
        bool taxResidencyVerified;
        bool amlCheckPassed;
        bool kycCheckPassed;
        string country;
        uint256 lastUpdated;
    }

    // Mapping from user address to verification data
    mapping(address => UserVerificationData) private userVerifications;

    // List of approved verifiers who can update compliance status
    mapping(address => bool) private approvedVerifiers;

    // Events
    event VerificationUpdated(address indexed user);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);

    // Modifier to restrict function access to approved verifiers
    modifier onlyVerifier() {
        require(
            approvedVerifiers[msg.sender] || owner() == msg.sender,
            "Not an approved verifier"
        );
        _;
    }

    constructor() {
        approvedVerifiers[msg.sender] = true;
    }

    /**
     * @dev Add a new approved verifier
     * @param verifier Address of the verifier to add
     */
    function addVerifier(address verifier) external onlyOwner {
        require(verifier != address(0), "Invalid verifier address");
        approvedVerifiers[verifier] = true;
        emit VerifierAdded(verifier);
    }

    /**
     * @dev Remove an approved verifier
     * @param verifier Address of the verifier to remove
     */
    function removeVerifier(address verifier) external onlyOwner {
        require(approvedVerifiers[verifier], "Not a verifier");
        approvedVerifiers[verifier] = false;
        emit VerifierRemoved(verifier);
    }

    /**
     * @dev Update user verification data
     * @param user Address of the user
     * @param verificationData The verification data to set
     */
    function updateUserVerifications(
        address user,
        UserVerificationData calldata verificationData
    ) external onlyVerifier {
        require(user != address(0), "Invalid user address");

        userVerifications[user] = verificationData;

        emit VerificationUpdated(user);
    }

    /**
     * @dev Get user verification data
     * @param user Address of the user
     * @return User's verification details
     */
    function getUserVerificationData(
        address user
    ) external view returns (UserVerificationData memory) {
        return userVerifications[user];
    }

    /**
     * @dev Check if a user is from one of the allowed countries
     * @param user Address of the user
     * @param allowedCountries Array of allowed country codes
     * @return Whether the user is from an allowed country
     */
    function isFromAllowedCountry(
        address user,
        string[] calldata allowedCountries
    ) public view returns (bool) {
        string memory userCountry = userVerifications[user].country;

        // Check if user is from an allowed country
        for (uint i = 0; i < allowedCountries.length; i++) {
            if (
                keccak256(bytes(userCountry)) ==
                keccak256(bytes(allowedCountries[i]))
            ) {
                return true;
            }
        }

        return false;
    }
}

/**
 * @title ComplianceManager
 * @dev Contract for managing different compliance requirements per asset
 */
contract ComplianceManager is Ownable {
    EnhancedComplianceRegistry public complianceRegistry;

    // Structure for asset compliance requirements
    struct AssetRequirements {
        bool requireAgeOver18;
        bool requireAgeOver21;
        bool requireAgeOver55;
        bool requireGovIDVerified;
        bool requireAddressVerified;
        bool requireAccreditedInvestor;
        bool requireTaxResidencyVerified;
        bool requireAmlCheckPassed;
        bool requireKycCheckPassed;
        string[] allowedCountries;
    }

    // Mapping from asset ID to compliance requirements
    mapping(uint256 => AssetRequirements) private assetRequirements;

    // Events
    event AssetRequirementsUpdated(uint256 indexed assetId);
    event CountryAddedToAsset(uint256 indexed assetId, string country);
    event CountryRemovedFromAsset(uint256 indexed assetId, string country);

    constructor(address complianceRegistryAddress) {
        require(
            complianceRegistryAddress != address(0),
            "Invalid compliance registry"
        );
        complianceRegistry = EnhancedComplianceRegistry(
            complianceRegistryAddress
        );
    }

    /**
     * @dev Set compliance requirements for an asset
     * @param assetId ID of the asset
     * @param requirements Compliance requirements for the asset
     */
    function setAssetRequirements(
        uint256 assetId,
        AssetRequirements calldata requirements
    ) external onlyOwner {
        assetRequirements[assetId] = requirements;
        emit AssetRequirementsUpdated(assetId);
    }

    /**
     * @dev Add an allowed country for an asset
     * @param assetId ID of the asset
     * @param country Country code to add
     */
    function addAllowedCountry(
        uint256 assetId,
        string calldata country
    ) external onlyOwner {
        // Check if country already exists
        bool exists = false;
        for (
            uint i = 0;
            i < assetRequirements[assetId].allowedCountries.length;
            i++
        ) {
            if (
                keccak256(
                    bytes(assetRequirements[assetId].allowedCountries[i])
                ) == keccak256(bytes(country))
            ) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            assetRequirements[assetId].allowedCountries.push(country);
            emit CountryAddedToAsset(assetId, country);
        }
    }

    /**
     * @dev Remove an allowed country for an asset
     * @param assetId ID of the asset
     * @param country Country code to remove
     */
    function removeAllowedCountry(
        uint256 assetId,
        string calldata country
    ) external onlyOwner {
        string[] storage countries = assetRequirements[assetId]
            .allowedCountries;

        for (uint i = 0; i < countries.length; i++) {
            if (keccak256(bytes(countries[i])) == keccak256(bytes(country))) {
                // Replace with the last element and pop
                countries[i] = countries[countries.length - 1];
                countries.pop();
                emit CountryRemovedFromAsset(assetId, country);
                break;
            }
        }
    }

    /**
     * @dev Get compliance requirements for an asset
     * @param assetId ID of the asset
     * @return Asset's compliance requirements
     */
    function getAssetRequirements(
        uint256 assetId
    ) external view returns (AssetRequirements memory) {
        return assetRequirements[assetId];
    }

    /**
     * @dev Check if a user is compliant for a specific asset
     * @param user Address of the user
     * @param assetId ID of the asset
     * @return Whether the user is compliant for the asset
     */
    function checkUserCompliance(
        address user,
        uint256 assetId
    ) public view returns (bool) {
        AssetRequirements memory requirements = assetRequirements[assetId];
        EnhancedComplianceRegistry.UserVerificationData
            memory userData = complianceRegistry.getUserVerificationData(user);

        // Check all required verifications
        if (requirements.requireAgeOver18 && !userData.ageOver18) return false;
        if (requirements.requireAgeOver21 && !userData.ageOver21) return false;
        if (requirements.requireAgeOver55 && !userData.ageOver55) return false;
        if (requirements.requireGovIDVerified && !userData.govIDVerified)
            return false;
        if (requirements.requireAddressVerified && !userData.addressVerified)
            return false;
        if (
            requirements.requireAccreditedInvestor &&
            !userData.accreditedInvestor
        ) return false;
        if (
            requirements.requireTaxResidencyVerified &&
            !userData.taxResidencyVerified
        ) return false;
        if (requirements.requireAmlCheckPassed && !userData.amlCheckPassed)
            return false;
        if (requirements.requireKycCheckPassed && !userData.kycCheckPassed)
            return false;

        // Check country restrictions
        if (requirements.allowedCountries.length > 0) {
            return
                complianceRegistry.isFromAllowedCountry(
                    user,
                    requirements.allowedCountries
                );
        }

        return true;
    }
}

/**
 * @title CustomizableRWAToken
 * @dev Implementation of a tokenized Real World Asset with customizable compliance requirements
 */
contract CustomizableRWAToken is ERC20, Ownable, Pausable {
    // Token properties
    uint8 private _decimals;
    uint256 public maxSupply;
    uint256 public assetId;

    // Compliance properties
    ComplianceManager public complianceManager;

    // Asset properties
    string public assetType; // e.g., "Real Estate", "T-Bill", "Art"
    string public assetIdentifier; // External reference to the underlying asset
    string public assetMetadataURI; // URI to more detailed asset information

    // Events
    event AssetMetadataUpdated(string newMetadataURI);

    /**
     * @dev Constructor
     * @param name The name of the token
     * @param symbol The symbol of the token
     * @param initialSupply Initial supply of tokens
     * @param tokenDecimals Number of decimals for the token
     * @param tokenMaxSupply Maximum supply of tokens
     * @param complianceManagerAddress Address of the compliance manager contract
     * @param tokenAssetId Unique ID for this asset's compliance requirements
     * @param assetType_ Type of the asset
     * @param assetIdentifier_ Identifier of the underlying asset
     * @param assetMetadataURI_ URI to asset metadata
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 tokenDecimals,
        uint256 tokenMaxSupply,
        address complianceManagerAddress,
        uint256 tokenAssetId,
        string memory assetType_,
        string memory assetIdentifier_,
        string memory assetMetadataURI_
    ) ERC20(name, symbol) {
        require(
            complianceManagerAddress != address(0),
            "Invalid compliance manager"
        );
        require(
            tokenMaxSupply >= initialSupply,
            "Max supply must be >= initial supply"
        );

        _decimals = tokenDecimals;
        maxSupply = tokenMaxSupply;
        assetId = tokenAssetId;

        // Set compliance manager
        complianceManager = ComplianceManager(complianceManagerAddress);

        // Set asset properties
        assetType = assetType_;
        assetIdentifier = assetIdentifier_;
        assetMetadataURI = assetMetadataURI_;

        // Mint initial supply to the contract creator
        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply);
        }
    }

    /**
     * @dev Returns the number of decimals used for the token
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Mint new tokens, respecting the maximum supply
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds maximum supply");
        require(
            isCompliant(to),
            "Recipient does not meet compliance requirements"
        );
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens from an address
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint256 amount) external {
        require(msg.sender == from || msg.sender == owner(), "Not authorized");
        _burn(from, amount);
    }

    /**
     * @dev Pause token transfers
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause token transfers
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Update the asset metadata URI
     * @param newMetadataURI New URI for asset metadata
     */
    function updateAssetMetadata(
        string calldata newMetadataURI
    ) external onlyOwner {
        assetMetadataURI = newMetadataURI;
        emit AssetMetadataUpdated(newMetadataURI);
    }

    /**
     * @dev Check if an address is eligible to hold the token
     * @param account Address to check
     * @return Whether the address meets compliance requirements
     */
    function isCompliant(address account) public view returns (bool) {
        return complianceManager.checkUserCompliance(account, assetId);
    }

    /**
     * @dev Override transfer function to check compliance
     */
    function transfer(
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        require(
            isCompliant(to),
            "Recipient does not meet compliance requirements"
        );
        return super.transfer(to, amount);
    }

    /**
     * @dev Override transferFrom function to check compliance
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        require(
            isCompliant(to),
            "Recipient does not meet compliance requirements"
        );
        return super.transferFrom(from, to, amount);
    }
}

/**
 * @title RWATokenFactory
 * @dev Factory contract for creating new RWA tokens with customized compliance requirements
 */
contract RWATokenFactory is Ownable {
    // Address of the compliance manager
    ComplianceManager public complianceManager;

    // Registry of all created tokens
    mapping(uint256 => address) public assetTokens;
    uint256 public nextAssetId;

    // Events
    event TokenCreated(
        uint256 indexed assetId,
        address tokenAddress,
        string name,
        string symbol
    );

    constructor(address complianceManagerAddress) {
        require(
            complianceManagerAddress != address(0),
            "Invalid compliance manager"
        );
        complianceManager = ComplianceManager(complianceManagerAddress);
        nextAssetId = 1;
    }

    /**
     * @dev Create a new RWA token with custom compliance requirements
     * @param name Token name
     * @param symbol Token symbol
     * @param initialSupply Initial supply of tokens
     * @param tokenDecimals Number of decimals for the token
     * @param tokenMaxSupply Maximum supply of tokens
     * @param assetType Type of the asset
     * @param assetIdentifier Identifier of the underlying asset
     * @param assetMetadataURI URI to asset metadata
     * @param requirements Compliance requirements for the asset
     * @return tokenAddress Address of the new token contract
     * @return assetId ID of the new asset
     */
    function createToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 tokenDecimals,
        uint256 tokenMaxSupply,
        string memory assetType,
        string memory assetIdentifier,
        string memory assetMetadataURI,
        ComplianceManager.AssetRequirements calldata requirements
    ) external onlyOwner returns (address tokenAddress, uint256 assetId) {
        // Get the next available asset ID
        assetId = nextAssetId++;

        // Set compliance requirements for this asset
        complianceManager.setAssetRequirements(assetId, requirements);

        // Create new token contract
        CustomizableRWAToken token = new CustomizableRWAToken(
            name,
            symbol,
            initialSupply,
            tokenDecimals,
            tokenMaxSupply,
            address(complianceManager),
            assetId,
            assetType,
            assetIdentifier,
            assetMetadataURI
        );

        // Transfer ownership to the factory owner
        token.transferOwnership(owner());

        // Register the token
        tokenAddress = address(token);
        assetTokens[assetId] = tokenAddress;

        emit TokenCreated(assetId, tokenAddress, name, symbol);

        return (tokenAddress, assetId);
    }
}
