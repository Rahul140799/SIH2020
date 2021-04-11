const compiler = require('solc');
const fs = require('fs-extra');
const Web3 = require('web3');
const path = require('path');
const logger = require('../../../../config/logger')(module);

const web3 = new Web3(new Web3.providers.HttpProvider("http://ganache:8545"));
const eventProvider = new Web3.providers.WebsocketProvider(
    "ws://ganache:8545"
);
web3.setProvider(eventProvider);  

let accounts = web3.eth.getAccounts().then(acc => {return acc});

const initialize = async() => {
    try{
        console.log("FILE ENTERED");
    const web3 = new Web3(new Web3.providers.HttpProvider("http://ganache:8545"));
    const eventProvider = new Web3.providers.WebsocketProvider(
        "ws://ganache:8545"
    );
    
    web3.setProvider(eventProvider);  
    const accounts = await web3.eth.getAccounts();
    const contractPath = path.resolve(__dirname,"../smartContract","scribe.sol");
    console.log(contractPath,"\n After this");
    const sourceCode = fs.readFileSync(contractPath,'utf8').toString();
    console.log("AFTER 0 ");
    const compiledCode = compiler.compile(sourceCode,1);
    console.log("AFTER 1 ",compiledCode);
    const buildPath = path.resolve(__dirname,"./build");
    console.log("AFTER 2");
    // console.log("CONTRACT : ",compiledCode.contracts[':Scribe']);
    fs.outputJSONSync(path.resolve(buildPath, "Message"+".json"),compiledCode.contracts[':Scribe']);
    contractInterface = JSON.parse(compiledCode.contracts[':Scribe'].interface);
    console.log("AFTER 3");
    const contractByteCode = compiledCode.contracts[':Scribe'].bytecode;
    const smartContract = new web3.eth.Contract(contractInterface);
    console.log("LOGGED");
    const myContract = await smartContract.deploy({data: contractByteCode}).send({from:accounts[0],gas:4700000});
    console.log(`contract  deployed to ${myContract.options.address}`);
    const receiptPath = path.resolve(buildPath, "eth-receipt"+".json");
    fs.writeJsonSync(receiptPath,myContract.options);
    const serialized = myContract.options.address;
    logger.log('info',`Admin Account ${accounts[0]}`);
    return serialized;  
    }catch(e){
        console.log("Error Occured : ",e);
        return e;
    }

}


module.exports.deploy = initialize;
module.exports.web3 = web3;
module.exports.accounts =accounts;