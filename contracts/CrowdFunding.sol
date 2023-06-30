// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import ERC721 from OpenZeppelin
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CrowdFunding is ERC721URIStorage {
    // Type declarations (funding)
    address private deployer;
    struct Campaign {
        address owner;
        string chainsafeStorageId;
        string title;
        string genre;
        string fictionType;
        string description;
        uint256 target;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        uint256 tokenId;
    }
    mapping(uint256 => Campaign) public campaigns;
    uint256 public numberOfCampaigns = 0;

    // Type declarations (NFT)
    uint256 public s_tokenCounter;

    // events
    event NftMinted(uint256 indexed tokenNumber, address minter);

    // modifiers
    modifier onlyDeployer() {
        require(
            msg.sender == deployer,
            "Only the deployer can call this function"
        );
        _;
    }

    // constructors
    constructor() ERC721("Nov3l NFT", "NOV") {
        deployer = msg.sender;
    }

    // errors
    error CrowdFunding__NotAdmin();

    // funding mutating functions
    function createCampaign(
        address _owner,
        string memory _chainsafeStorageId,
        string memory _title,
        string memory _genre,
        string memory _fictionType,
        string memory _description,
        uint256 _target,
        string memory _image,
        string memory novelTokenUri
    ) public payable returns (uint256) {
        // ----------- campaign -------------
        Campaign storage campaign = campaigns[numberOfCampaigns];

        campaign.owner = _owner;
        campaign.chainsafeStorageId = _chainsafeStorageId;
        campaign.title = _title;
        campaign.genre = _genre;
        campaign.fictionType = _fictionType;
        campaign.description = _description;
        campaign.target = _target;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        // ----------- NFT -------------

        s_tokenCounter++;
        uint256 newTokenId = s_tokenCounter;

        _safeMint(msg.sender, newTokenId);

        _setTokenURI(newTokenId, novelTokenUri);

        campaign.tokenId = newTokenId;

        emit NftMinted(s_tokenCounter, msg.sender);

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;
        Campaign storage campaign = campaigns[_id];
        campaign.donators.push(msg.sender);
        campaign.donations.push(msg.value);
        (bool sent, ) = payable(campaign.owner).call{value: amount}("");
        if (sent) {
            campaign.amountCollected += amount;
        }
    }

    // funding view functions

    function getDonators(
        uint256 _id
    ) public view returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);
        for (uint256 i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }

    // function for deployer to change image URLs in case of NSFW images or user requests
    function changeCampaignImage(
        uint256 _index,
        string memory _newImageURL
    ) public onlyDeployer returns (uint256) {
        // change image of campaign at index to new string
        campaigns[_index].image = _newImageURL;
        return _index;
    }

    // function for donating to project in general to deployer account
    function donateToSite() public payable returns (bool) {
        uint256 amount = msg.value;
        (bool sent, ) = payable(deployer).call{value: amount}("");
        return sent;
    }
}
