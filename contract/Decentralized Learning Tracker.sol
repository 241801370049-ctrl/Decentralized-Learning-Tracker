// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title DecentralizedLearningTracker
 * @dev A smart contract for tracking and verifying learning achievements on the blockchain
 */
contract DecentralizedLearningTracker {
    
    // Structure to represent a learning achievement
    struct Achievement {
        uint256 id;
        string title;
        string description;
        address learner;
        address verifier;
        uint256 timestamp;
        bool isVerified;
        string skillCategory;
        uint8 proficiencyLevel; // 1-10 scale
    }
    
    // Structure to represent a learner profile
    struct LearnerProfile {
        address learnerAddress;
        string name;
        uint256 totalAchievements;
        uint256 totalPoints;
        bool isActive;
        uint256 registrationDate;
    }
    
    // State variables
    mapping(uint256 => Achievement) public achievements;
    mapping(address => LearnerProfile) public learnerProfiles;
    mapping(address => uint256[]) public learnerAchievements;
    mapping(address => bool) public authorizedVerifiers;
    
    uint256 private achievementCounter;
    address public admin;
    
    // Events
    event LearnerRegistered(address indexed learner, string name, uint256 timestamp);
    event AchievementRecorded(
        uint256 indexed achievementId,
        address indexed learner,
        string title,
        uint256 timestamp
    );
    event AchievementVerified(
        uint256 indexed achievementId,
        address indexed verifier,
        uint256 timestamp
    );
    event VerifierAuthorized(address indexed verifier, uint256 timestamp);
    
    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyAuthorizedVerifier() {
        require(authorizedVerifiers[msg.sender], "Only authorized verifiers can verify achievements");
        _;
    }
    
    modifier onlyRegisteredLearner() {
        require(learnerProfiles[msg.sender].isActive, "Learner must be registered and active");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        achievementCounter = 0;
        authorizedVerifiers[admin] = true;
    }
    
    /**
     * @dev Function 1: Register a new learner in the system
     * @param _name The name of the learner
     */
    function registerLearner(string memory _name) external {
        require(!learnerProfiles[msg.sender].isActive, "Learner already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        
        learnerProfiles[msg.sender] = LearnerProfile({
            learnerAddress: msg.sender,
            name: _name,
            totalAchievements: 0,
            totalPoints: 0,
            isActive: true,
            registrationDate: block.timestamp
        });
        
        emit LearnerRegistered(msg.sender, _name, block.timestamp);
    }
    
    /**
     * @dev Function 2: Record a new learning achievement
     * @param _title Title of the achievement
     * @param _description Description of what was learned
     * @param _skillCategory Category of the skill (e.g., "Programming", "Design", etc.)
     * @param _proficiencyLevel Proficiency level from 1-10
     */
    function recordAchievement(
        string memory _title,
        string memory _description,
        string memory _skillCategory,
        uint8 _proficiencyLevel
    ) external onlyRegisteredLearner {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_proficiencyLevel >= 1 && _proficiencyLevel <= 10, "Proficiency level must be between 1-10");
        
        achievementCounter++;
        
        achievements[achievementCounter] = Achievement({
            id: achievementCounter,
            title: _title,
            description: _description,
            learner: msg.sender,
            verifier: address(0),
            timestamp: block.timestamp,
            isVerified: false,
            skillCategory: _skillCategory,
            proficiencyLevel: _proficiencyLevel
        });
        
        learnerAchievements[msg.sender].push(achievementCounter);
        learnerProfiles[msg.sender].totalAchievements++;
        learnerProfiles[msg.sender].totalPoints += _proficiencyLevel;
        
        emit AchievementRecorded(achievementCounter, msg.sender, _title, block.timestamp);
    }
    
    /**
     * @dev Verify a learning achievement
     * @param _achievementId ID of the achievement to verify
     */
    function verifyAchievement(uint256 _achievementId) external onlyAuthorizedVerifier {
        require(_achievementId > 0 && _achievementId <= achievementCounter, "Invalid achievement ID");
        require(!achievements[_achievementId].isVerified, "Achievement already verified");
        
        achievements[_achievementId].isVerified = true;
        achievements[_achievementId].verifier = msg.sender;
        
        // Bonus points for verified achievements
        address learner = achievements[_achievementId].learner;
        learnerProfiles[learner].totalPoints += 5;
        
        emit AchievementVerified(_achievementId, msg.sender, block.timestamp);
    }
    
    // Additional helper functions
    
    /**
     * @dev Authorize a new verifier (only admin)
     * @param _verifier Address of the verifier to authorize
     */
    function authorizeVerifier(address _verifier) external onlyAdmin {
        require(_verifier != address(0), "Invalid verifier address");
        authorizedVerifiers[_verifier] = true;
        emit VerifierAuthorized(_verifier, block.timestamp);
    }
    
    /**
     * @dev Get learner's achievements
     * @param _learner Address of the learner
     * @return Array of achievement IDs
     */
    function getLearnerAchievements(address _learner) external view returns (uint256[] memory) {
        return learnerAchievements[_learner];
    }
    
    /**
     * @dev Get achievement details
     * @param _achievementId ID of the achievement
     * @return Achievement struct
     */
    function getAchievement(uint256 _achievementId) external view returns (Achievement memory) {
        require(_achievementId > 0 && _achievementId <= achievementCounter, "Invalid achievement ID");
        return achievements[_achievementId];
    }
    
    /**
     * @dev Get total number of achievements in the system
     * @return Total achievement count
     */
    function getTotalAchievements() external view returns (uint256) {
        return achievementCounter;
    }
}
