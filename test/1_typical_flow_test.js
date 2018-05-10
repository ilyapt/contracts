const BigNumber = require('bignumber.js');
const ERC20 = artifacts.require("just4tests/ERCToken");
const OptionToken = artifacts.require("OptionToken");
const OptionSale = artifacts.require('OptionSale');
const OptionFactory = artifacts.require('OptionFactory');
const OptionHub = artifacts.require('OptionHub');

const optionPrice = 0.01; // Eth
const strikePrice = 0.09; // Eth (typically full tokenPrice - optionPrice)

contract('Typical flow test', async (accounts) => {

    let ercToken, factory, optionSale, optionToken, tokenstarter, tokenstarterAdmin, startup, startupBalance, investor, tokenCount;
  
    before(async () => {
        ercToken = await ERC20.deployed();
        factory  = await OptionFactory.deployed();
        hub      = await OptionHub.deployed();


        let tokenDecimals = (new BigNumber(10)).exponentiatedBy((await ercToken.decimals()).toNumber());
        tokenCount = (count) => tokenDecimals.multipliedBy(count);

        tokenstarter      = accounts[0];
        tokenstarterAdmin = accounts[1];
        startup           = accounts[2];
        investor          = accounts[3];
    });

    it('Configuring optionHub', async () => {
        await hub.setAdmin(tokenstarterAdmin, {from: tokenstarter});
        await hub.setFactory(factory.address, {from: tokenstarterAdmin});
    });

    it('Startup is creating new option smart-contract', async () => {
        // current timestamp
        const _now = web3.eth.getBlock(web3.eth.blockNumber).timestamp;

        // option configuration
        let params = [
            web3.toWei(optionPrice, 'ether'),
            _now + 100000,
            ercToken.address,
            web3.toWei(strikePrice, 'ether'),
            _now + 200000
        ];

        // Call to receive option sale contract address
        let saleAddr = await factory.newOptionSale.call(...params, {from: startup});
        // Make transaction
        await factory.newOptionSale(...params, {from: startup});

        optionSale = await OptionSale.at(saleAddr);
        optionToken = await OptionToken.at(await optionSale.option());
    });

    it('Checking option contract address in OptionHub', async () => {
        let value = await hub.options(0);
        assert.equal(value.toString(), optionSale.address);
    });

    it('Startup transfered (minted) 500 erc-token to option sale contract', async () => {
        await ercToken.mint(optionSale.address, tokenCount(500).toString(), {from: startup});

        let value = await ercToken.balanceOf(optionSale.address);
        assert.equal(value.toNumber(), tokenCount(500).toString());
    });

    it('Investor bought 100 options', async () => {
        await optionSale.sendTransaction({from: investor, value: web3.toWei(1, 'ether')});

        let value = await optionToken.balanceOf(investor);
        assert.equal(value.toNumber(), tokenCount(100));
    });

    it('On balance of the option should be 100 erc-tokens', async () => {
        let value = await ercToken.balanceOf(optionToken.address);
        assert.equal(value.toNumber(), tokenCount(100));
    });

    it('Investor are buing out 50 options and gets 50 erc-tokens', async () => {
        await optionToken.sendTransaction({from: investor, value: web3.toWei(4.5, 'ether')});

        let value = await ercToken.balanceOf(investor);
        assert.equal(value.toNumber(), tokenCount(50));
    });

    it('He also keep 50 options', async () => {
        let value = await optionToken.balanceOf(investor);
        assert.equal(value.toNumber(), tokenCount(50));
    });
});

