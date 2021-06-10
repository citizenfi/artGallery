// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenizedArtFactory is ERC721, Ownable {
    using SafeMath for uint256;

    ERC20 cifiTokenContractTest =
        ERC20(0xe56aB536c90E5A8f06524EA639bE9cB3589B8146);
    uint256 FEE = 100;
    uint8 cifiDecimals = cifiTokenContractTest.decimals();
    uint256 public feeAmount = FEE.mul(10**cifiDecimals).div(100);

    address feeWallet = address(0x000000000000000000000000);

    string public Artname;
    string public Artsymbol;
    string public Artdescription;
    string public Arturi;
    bool public isPrivate;

    // Total tokens starts at 0 because each new token must be minted and the
    // _mint() call adds 1 to totalTokens
    uint256 public totalTokens = 0;

    address public Artcreator;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) ownedTokens;

    // Metadata is a URL that points to a json dictionary
    mapping(uint256 => string) tokenIdToMetadata;

    mapping(uint256 => string) tokenID_symbol;
    mapping(uint256 => uint256) tokenID_amount;

    mapping(string => address) acceptedTokens;

    string[] public acceptedTokenSymbols;

    event MetadataAssigned(
        address indexed _owner,
        uint256 _tokenId,
        string _url
    );
    event Mint(string url, uint256 tokenId, string symbol, uint256 amount);

    /**
     * a registry function that iis been called by the NFT registry smart contract
     */

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _uri,
        address _caller,
        bool _isPrivate
    ) ERC721(_name, _symbol) {
        Artname = _name;
        Artsymbol = _symbol;
        Artdescription = _description;
        Arturi = _uri;
        Artcreator = _caller;
        isPrivate = _isPrivate;
        totalTokens = 0;
    }

    /**
     * this function helps with queries to Fetch the metadata for a givine token id
     */
    function getMetadataAtID(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return tokenIdToMetadata[_tokenId];
    }

    /**
     * this function helps with queries to Fetch all the tokens that the address owns by givine address
     */
    function tokensOf(address _owner) public view returns (uint256[] memory) {
        require(_owner != address(0), "invalid owner");
        return ownedTokens[_owner];
    }

    /**
     * this function allows to approve more than one token id at once
     */
    function approveMany(address _to, uint256[] memory _tokenIds) public {
        /* Allows bulk-approval of many tokens. This function is useful for
      exchanges where users can make a single tx to enable the call of
      transferFrom for those tokens by an exchange contract. */
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // approve handles the check for if one who is approving is the owner.
            approve(_to, _tokenIds[i]);
        }
    }

    /**
     * this function allows to approve all the tokens the address owns at once
     */
    function approveAll(address _to) public {
        uint256[] memory tokens = tokensOf(msg.sender);
        for (uint256 t = 0; t < tokens.length; t++) {
            approve(_to, tokens[t]);
        }
    }

    /**
     * this overload function allows to transfer tokens and updates all the mapping queries(without filling the URI)
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        require(from != address(0), "invalid address");
        require(to != address(0), "invalid address");
        _safeTransfer(from, to, tokenId, "");
        uint256[] memory fromIds = ownedTokens[from];
        uint256[] memory newFromIds = new uint256[](fromIds.length - 1);
        uint256[] storage toIds = ownedTokens[to];
        toIds.push(tokenId);
        ownedTokens[to] = toIds;
        uint256 j = 0;
        for (uint256 i = 0; i < fromIds.length; i++) {
            if (fromIds[i] != tokenId) newFromIds[j++] = (fromIds[i]);
        }
        ownedTokens[from] = newFromIds;
    }

    /**
     * this function allows to mint more of your Art
     */
    function mint(
        string memory url,
        string memory tokenSymbol,
        uint256 amount
    ) public {
        require(msg.sender == Artcreator);
        totalTokens = totalSupply().add(1);
        // The index of the newest token is at the # totalTokens.
        _mint(msg.sender, totalTokens);
        // assign address to array of owned tokens aned you can qury what ids the address owns
        uint256[] storage ids = ownedTokens[msg.sender];
        ids.push(totalTokens);
        ownedTokens[msg.sender] = ids;
        // _mint() call adds 1 to total tokens, but we want the token at index - 1
        tokenIdToMetadata[totalTokens] = url;

        ERC20 acceptedToken = ERC20(acceptedTokens[tokenSymbol]);
        if (acceptedToken != cifiTokenContractTest) {
            cifiTokenContractTest.transferFrom(
                msg.sender,
                feeWallet,
                feeAmount
            );
        }
        acceptedToken.transferFrom(msg.sender, address(this), feeAmount);
        tokenID_symbol[totalTokens] = tokenSymbol;
        tokenID_amount[totalTokens] = amount;

        emit Mint(url, totalTokens, tokenSymbol, amount);
    }

    /**
     * this function allows you to change the Registry privacy if its false it will change to true, if its true it will change to false
     */

    function changeGalleryPrivacy() public {
        require(msg.sender == Artcreator);
        if (isPrivate == true) {
            isPrivate = false;
        } else if (isPrivate == false) {
            isPrivate = true;
        }
    }

    /**
     * this function allows you burn your Art
     */
    function burn(uint256 _id) public returns (bool) {
        address owner = ownerOf(_id);
        string memory tokenSymbol = tokenID_symbol[_id];
        uint256 amount = tokenID_amount[_id];
        ERC20 acceptedToken = ERC20(acceptedTokens[tokenSymbol]);
        acceptedToken.transferFrom(address(this), owner, amount);
        _burn(_id);
        return true;
    }

    function getTotalTokens() public view returns (uint256) {
        return totalTokens;
    }

    function addAcceptedToken(
        address acceptedTokenAddress,
        string memory acceptedTokenSymbol
    ) public onlyOwner returns (bool) {
        acceptedTokens[acceptedTokenSymbol] = acceptedTokenAddress;
        acceptedTokenSymbols.push(acceptedTokenSymbol);
        return true;
    }
}
