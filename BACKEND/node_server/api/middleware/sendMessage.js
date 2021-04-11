var unirest = require("unirest");
const req = unirest("POST", "https://www.fast2sms.com/dev/bulk");
const logger = require('../../config/logger')(module);

module.exports.sendOTP = async(phno, otp) =>  {
    var messageString = "Please specify this OTP to the doctor : " + otp;
    console.log(messageString);
    req.headers({
        "authorization": "aefkJGosAbt4CzKpjhYvM1rmUgyqWZHwl5ud9XF3T6OSDnBRLP3TnLhQiEDNBIvRVAsUFok8MJe0qCO5"
    });

    req.form({
        "sender_id": "FSTSMS",
        "message": messageString,
        "language": "english",
        "route": "p",
        "numbers": phno,
    });

    req.end(async function (res) {
        if (res.error) {
            logger.log('error',`An error occured at sending message ${res.error}`);
            throw new Error(res.error);
        }        
    });

}