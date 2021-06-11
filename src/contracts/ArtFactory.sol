// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ArtFactory is ERC721 {
    using SafeMath for uint256;

    string public Artname;
    string public Artsymbol;
    string public Artdescription;

    address public Artcreater;
    // Total tokens starts at 0 because each new token must be minted and the
    // _mint() call adds 1 to totalTokens

    event Mint(string url, uint256 tokenId);

    /**
     * a registry function that iis been called by the NFT registry smart contract
     */

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _description,
        address creater
    ) ERC721(_name, _symbol) {
        Artname = _name;
        Artsymbol = _symbol;
        Artdescription = _description;
        Artcreater = creater;
        _setBaseURI("https://ipfs.io/ipfs/");
    }

    function setURIPrefix(string memory baseURI) public {
        require(msg.sender == Artcreater);
        _setBaseURI(baseURI);
    }

    /**
     * this function assignes the URI to automatically add the id number at the end of the URI
     */
    function assignDataToToken(uint256 id, string memory uri) public {
        require(_msgSender() == ownerOf(id), "invalid token owner");
        _setTokenURI(id, uri);
    }

    /**
     * this function helps with queries to Fetch all the tokens that the address owns by givine address
     */
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        require(owner != address(0), "invalid owner");
        uint256 length = balanceOf(owner);
        uint256[] memory tokens = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
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
        uint256[] memory tokens = tokensOfOwner(msg.sender);
        for (uint256 t = 0; t < tokens.length; t++) {
            approve(_to, tokens[t]);
        }
    }

    /**
     * this function allows to mint more of your Art
     */
    function mint(string memory url) external returns (bool) {
        require(msg.sender == Artcreater);
        uint256 currentTokenCount = totalSupply().add(1);
        // The index of the newest token is at the # totalTokens.
        _mint(msg.sender, currentTokenCount);
        _setTokenURI(currentTokenCount, url);
        emit Mint(url, currentTokenCount);
        return true;
    }

    /**
     * this function allows you burn your Art
     */
    function burn(uint256 _id) public returns (bool) {
        require(
            _isApprovedOrOwner(_msgSender(), _id),
            "caller is not owner nor approved"
        );
        _burn(_id);
        return true;
    }
}