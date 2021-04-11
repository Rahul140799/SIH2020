const fs = require('fs-extra');
const { web3, accounts } = require('./deploy.js');
const { prescriptionSchema } = require('../../Patient/patient_schema.js');



const getContractObject = () => {
    const contractReceipt = require('./build/eth-receipt.json');
    const compiledContract = require('./build/Message.json');
    return new web3.eth.Contract(JSON.parse(compiledContract.interface),contractReceipt.address);
}

const getAccounts = () => {
   return  web3.eth.getAccounts().then(async (accounts) => {
       return accounts;
   });
}


const getMessage = async() => {
    const contractObject = getContractObject();
    const accounts = await web3.eth.getAccounts();
    const result = await contractObject.methods
                   .getGreet()
                   .call({from:accounts[2]});
    console.log(result);
    return result;

}

const createDoctor = async(name, phno, email, password) =>{
    console.log("CREATE DOCTOR : ",name,phno,email,password);
    const count = await getDocCount();
    const id = (parseInt(count,10) + 1);
    const contractObject = getContractObject();
    return web3.eth.getAccounts().then(async (accounts) => {
        let hash = {}
      await  contractObject.methods.addDoctor(name, phno, email, password, accounts[id]).send({from:accounts[0],gas:'1000000'},(err,thash) => {
           console.log(thash,accounts[id]);
           hash = thash;
        });
        return {account:accounts[id],hash:hash};
    });

}

const getDoctor = async(address) =>{
    console.log("GET DOCTOR : ",address);
    const contractObject = getContractObject();
    try{
        return await contractObject.methods.getDoctor(address).call().then((doc) => {return doc});
   }
    catch(e){
        return e;
    }
    
}

const getDocCount  = async() => {
    const contractObject = getContractObject();
    return await contractObject.methods.doctorCount().call().then((c) => { return c });
}

const getPatCount  = async() => {
    const contractObject = getContractObject();
    return await contractObject.methods.patientCount().call().then((c) => { return c });
}

const createPatient = async(name, phno, email, patientQrCode, dob, gender) =>{
    console.log("CREATE PATIENT : ",name,phno,email);
    const contractObject = getContractObject();
    return web3.eth.getAccounts().then(async (accounts) => {
        let hash = {}
        console.log(accounts[0]);
        await  contractObject.methods.addPatient(name, phno, email, patientQrCode, dob, gender).send({from:accounts[0],gas:'1000000'},(err,thash) => {
            console.log(thash,phno);
            hash = thash;
            });
        return {account:patientQrCode,hash:hash};
    });
}

const getPatient = async(patientQrCode,address) =>{
    console.log("GET PATIENT : ",patientQrCode);
    const contractObject = getContractObject();
    try{
        return await  contractObject.methods.getPatient(patientQrCode).call({from:address}).then((patient) => {
            console.log("PAT : ",patient);
            return patient;
        });
        

   }
    catch(e){
        return e;
    }
    
}


const getPatientForAdmin = async(patientQrCode) =>{
    try{
        console.log("GET PATIENT : ",patientQrCode);
        const contractObject = getContractObject();
        return web3.eth.getAccounts().then(async (accounts) => {
            return await contractObject.methods.getPatient(patientQrCode).call({from:accounts[0]}).then((patient) => {
                console.log("PAT : ",patient);
                if(patient[0]&&patient[1])
                {
                    return {id:patient[0], name:patient[1], email:patient[2], phone:patient[3], doctorVisited:patient[4], prescriptionCount:patient[6], dob:patient[7], gender:patient[8]};
                }
                
            });     
        });
   }
    catch(e){
        return e;
    }
    
}


const createPrescription = async(medicines, symptoms, diagnosis, advice, patientQrCode, doctorAddress) => {
    try{
        console.log("CREATE PRESCRIPTION : ",patientQrCode);
        const contractObject = getContractObject();
        var today = new Date();
        var date = today.getFullYear()+'-'+(today.getMonth()+1)+'-'+today.getDate();
        var time = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();
        var dateTime = date+'T'+time;
        let hash = "";
        await contractObject.methods.createPrescription(medicines, symptoms, diagnosis, advice, dateTime, patientQrCode).send({from:doctorAddress,gas:'1000000'},(err,thash) => {
            console.log("PRESCRIPTION",thash);
            hash = thash;
            });
        return {hash:hash, prescriptionName: dateTime};
    }
    catch(e){
        return { error:e };
    }
}

const getPrescription = async (prescriptionId, patientQrCode, doctorAddress) => {
    try{
        console.log("GET PRESCRIPTION : ",prescriptionId);
        const contractObject = getContractObject();
        return await contractObject.methods.getPrescription(prescriptionId, patientQrCode).call({from:doctorAddress}).then((prescription) => {
            console.log("PRESCRIPTION : ",prescription);
            return {prescriptionId:prescription["0"], medicines: prescription["1"], symptoms:prescription["2"], diagnosis:prescription["3"], advice:prescription["4"], date:prescription["5"], doctorName:prescription["6"]};
        });
    }
    catch(e){
        return { error:e } ;
    }
}

const giveDoctorAccessToPatientRecords = async (patientQrCode, doctorAddress) => {
    try{
        console.log("GIVE ACCESS TO PATIENT : ", patientQrCode);
        const contractObject = getContractObject();
        let hash = "";
        await contractObject.methods.giveDoctorAccessToPatientRecords(patientQrCode).send({from:doctorAddress,gas:'1000000'},(err,thash) => {
            console.log("ACCESS GRANTED",thash);
            hash = thash;
            });
        return {hash:hash,access:"GRANTED"};
    }
    catch(e){
        return { error:e, access:"DENIED" } ;
    }
}

const checkPermission = async(patientQrCode, doctorAddress) => {
    try{
        console.log("ACCESS CALL ");
        const contractObject = getContractObject();
        return await contractObject.methods.checkPermission(patientQrCode).call({from:doctorAddress}).then((access) => {
            console.log("ACCESS : ",access);
            return access;
        });
    }
    catch(e){
        console.log(e);
        return false;
    }
}

const getBalance = async(doctorAddress) => {
    try {
        let bal = "";
        await web3.eth.getBalance(doctorAddress, async (err, balance) => {
            if(err){
                return err;
            }
            console.log("BALANCE :  ",balance);
            bal = web3.utils.fromWei(balance, "ether") + " ETH";
            // web3.eth.getPastLogs({
            //     address: doctorAddress
            // })
            // .then((logs) => {
            //     console.log("PAST LOGS : ",logs);
            // })
          });
          return bal;
    } catch (e) {
        return e;
    }
}


module.exports.getAccounts = getAccounts;
module.exports.getMessage = getMessage;
module.exports.getDocCount = getDocCount;
module.exports.createDoctor = createDoctor;
module.exports.getDoctor = getDoctor;
module.exports.createPatient = createPatient;
module.exports.getPatient = getPatient;
module.exports.patientCount = getPatCount;
module.exports.getPatientForAdmin = getPatientForAdmin;
module.exports.createPrescription = createPrescription;
module.exports.getPrescription = getPrescription;
module.exports.giveDoctorAccessToPatientRecords = giveDoctorAccessToPatientRecords;
module.exports.checkPermission = checkPermission;
module.exports.getBalance = getBalance;