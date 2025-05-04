// Test file to demonstrate how to use the CustomizableRWA contracts

// Example deployment script (pseudocode)
async function deployContracts() {
  // 1. Deploy the EnhancedComplianceRegistry
  const ComplianceRegistry = await ethers.getContractFactory(
    "EnhancedComplianceRegistry"
  );
  const complianceRegistry = await ComplianceRegistry.deploy();
  await complianceRegistry.deployed();
  console.log("ComplianceRegistry deployed to:", complianceRegistry.address);

  // 2. Deploy the ComplianceManager with the registry address
  const ComplianceManager = await ethers.getContractFactory(
    "ComplianceManager"
  );
  const complianceManager = await ComplianceManager.deploy(
    complianceRegistry.address
  );
  await complianceManager.deployed();
  console.log("ComplianceManager deployed to:", complianceManager.address);

  // 3. Deploy the RWATokenFactory with the compliance manager address
  const RWATokenFactory = await ethers.getContractFactory("RWATokenFactory");
  const rwaTokenFactory = await RWATokenFactory.deploy(
    complianceManager.address
  );
  await rwaTokenFactory.deployed();
  console.log("RWATokenFactory deployed to:", rwaTokenFactory.address);

  return { complianceRegistry, complianceManager, rwaTokenFactory };
}

// Example of setting up verification data for a user
async function verifyUser(complianceRegistry, userAddress) {
  // Set up verification data for a user
  const verificationData = {
    ageOver18: true,
    ageOver21: true,
    ageOver55: false,
    govIDVerified: true,
    addressVerified: true,
    accreditedInvestor: true,
    taxResidencyVerified: true,
    amlCheckPassed: true,
    kycCheckPassed: true,
    country: "US",
    lastUpdated: Math.floor(Date.now() / 1000),
  };

  await complianceRegistry.updateUserVerifications(
    userAddress,
    verificationData
  );
  console.log("User verification data updated for:", userAddress);
}

// Example of creating a new RWA token with specific compliance requirements
async function createRWAToken(rwaTokenFactory, complianceManager) {
  // First, define the compliance requirements for this specific asset
  const assetRequirements = {
    requireAgeOver18: true,
    requireAgeOver21: false,
    requireAgeOver55: false,
    requireGovIDVerified: true,
    requireAddressVerified: true,
    requireAccreditedInvestor: true, // This token requires accredited investor status
    requireTaxResidencyVerified: true,
    requireAmlCheckPassed: true,
    requireKycCheckPassed: true,
    allowedCountries: [], // We'll add countries separately
  };

  // Create the token
  const result = await rwaTokenFactory.createToken(
    "Premium Real Estate Token",
    "PRET",
    ethers.utils.parseEther("1000"), // Initial supply
    18, // Decimals
    ethers.utils.parseEther("10000"), // Max supply
    "Real Estate",
    "Premium Manhattan Property ID: NY12345",
    "https://example.com/assets/ny12345",
    assetRequirements
  );

  // Get the transaction receipt to extract the asset ID
  const receipt = await result.wait();
  const event = receipt.events.find((e) => e.event === "TokenCreated");
  const assetId = event.args.assetId;
  const tokenAddress = event.args.tokenAddress;

  console.log("New RWA Token created:");
  console.log("- Asset ID:", assetId.toString());
  console.log("- Token Address:", tokenAddress);

  // Add allowed countries for this asset
  await complianceManager.addAllowedCountry(assetId, "US");
  await complianceManager.addAllowedCountry(assetId, "CA");
  await complianceManager.addAllowedCountry(assetId, "GB");
  console.log("Added allowed countries: US, CA, GB");

  return { assetId, tokenAddress };
}

// Example of creating a different RWA token with different compliance requirements
async function createSecondRWAToken(rwaTokenFactory, complianceManager) {
  // Define different compliance requirements for this asset
  const assetRequirements = {
    requireAgeOver18: true,
    requireAgeOver21: true, // This token requires users to be 21+
    requireAgeOver55: false,
    requireGovIDVerified: true,
    requireAddressVerified: true,
    requireAccreditedInvestor: false, // This token doesn't require accredited investor status
    requireTaxResidencyVerified: true,
    requireAmlCheckPassed: true,
    requireKycCheckPassed: true,
    allowedCountries: [], // We'll add countries separately
  };

  // Create the token
  const result = await rwaTokenFactory.createToken(
    "Winery Investment Token",
    "WINE",
    ethers.utils.parseEther("5000"), // Initial supply
    18, // Decimals
    ethers.utils.parseEther("50000"), // Max supply
    "Business",
    "Napa Valley Winery Investment ID: WIN789",
    "https://example.com/assets/win789",
    assetRequirements
  );

  // Get the transaction receipt to extract the asset ID
  const receipt = await result.wait();
  const event = receipt.events.find((e) => e.event === "TokenCreated");
  const assetId = event.args.assetId;
  const tokenAddress = event.args.tokenAddress;

  console.log("New Winery Investment Token created:");
  console.log("- Asset ID:", assetId.toString());
  console.log("- Token Address:", tokenAddress);

  // Add allowed countries for this asset
  await complianceManager.addAllowedCountry(assetId, "US");
  console.log("Added allowed country: US only");

  return { assetId, tokenAddress };
}

// Example of how a user interacts with the tokens
async function userInteraction(
  realEstateTokenAddress,
  wineryTokenAddress,
  userAddress
) {
  // Load the tokens
  const RWAToken = await ethers.getContractFactory("CustomizableRWAToken");
  const realEstateToken = await RWAToken.attach(realEstateTokenAddress);
  const wineryToken = await RWAToken.attach(wineryTokenAddress);

  // Check if user is compliant for each token
  const isCompliantForRealEstate = await realEstateToken.isCompliant(
    userAddress
  );
  const isCompliantForWinery = await wineryToken.isCompliant(userAddress);

  console.log("User compliance checks:");
  console.log("- Eligible for Real Estate Token:", isCompliantForRealEstate);
  console.log("- Eligible for Winery Token:", isCompliantForWinery);

  // If the user is not compliant for the winery token, it's likely because they're missing
  // a specific requirement like ageOver21 verification
}

// Main function to run all examples
async function main() {
  // Deploy contracts
  const { complianceRegistry, complianceManager, rwaTokenFactory } =
    await deployContracts();

  // Verify a user (replace with actual user address)
  const userAddress = "0x123..."; // Example user address
  await verifyUser(complianceRegistry, userAddress);

  // Create two different RWA tokens with different compliance requirements
  const { tokenAddress: realEstateTokenAddress } = await createRWAToken(
    rwaTokenFactory,
    complianceManager
  );
  const { tokenAddress: wineryTokenAddress } = await createSecondRWAToken(
    rwaTokenFactory,
    complianceManager
  );

  // Interact with the tokens as a user
  await userInteraction(
    realEstateTokenAddress,
    wineryTokenAddress,
    userAddress
  );
}

// Uncomment to run this example
// main()
//   .then(() => process.exit(0))
//   .catch(error => {
//     console.error(error);
//     process.exit(1);
//   });

// This example demonstrates how to:
// 1. Set up a customizable compliance system for RWA tokens
// 2. Create different tokens with different compliance requirements
// 3. Verify users and check their eligibility for different tokens
//
// In a real implementation, you would:
// - Use a more secure approach for storing and updating user verification data
// - Implement KYC verification via trusted third parties
// - Add more detailed asset metadata and compliance checking
// - Implement additional features like whitelisting/blacklisting
// - Add time-based constraints or token vesting schedules
