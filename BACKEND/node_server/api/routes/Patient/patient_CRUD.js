const express = require('express');
const router = express();
const { createPatient, getPatient, patientCount, getPrescription } = require("../Blockchain/connection/handlers.js");
const { sendOTP } = require("../../middleware/sendMessage.js");
const { patientSchema, patientDetailSchema } = require('./patient_schema');
const { auth } = require('../../middleware/auth.js');
const QRCode  = require('qrcode');
const { sendMail } = require('../../middleware/sendmail.js');
const logger = require('../../../config/logger.js')(module);



//helper  Function
function makeQrCode(length) {
    var result = '';
    var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    var charactersLength = characters.length;
    for (var i = 0; i < length; i++) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    return result;
}

function makeOTP(length) {
    var result = '';
    var characters = '0123456789';
    var charactersLength = characters.length;
    for (var i = 0; i < length; i++) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    return result;
}



/**
 * @swagger
 * /api/patient/count:
 *   get:
 *      tags:
 *          - patient
 *      description: Returns the count of patient registered in the blockchain
 *      responses:
 *          200:
 *             description: A json containing a message
 *             schema:
 *                  type: object
 *                  properties:
 *                          count:
 *                              type: string
 */
router.get('/count', async (req, res, next) => {
    const count = await patientCount();
    res.status(200).json({ count: count });
});

/**
 * @swagger
 * /api/patient/create:
 *   post:
 *      tags:
 *          - patient
 *      description: to create a new patient 
 *      consumes:
 *       - application/json
 *      parameters:
 *       - name: auth-token
 *         description: auth token got from  login.
 *         in: header
 *         type: string
 *       - in: body
 *         name: patient
 *         schema :
 *              type: object
 *              required:
 *                  - name
 *                  - phno
 *                  - email
 *                  - dob
 *                  - gender
 *              properties:
 *                  name:
 *                      type: string
 *                  phno:
 *                      type: string
 *                  email:
 *                      type: string
 *                  dob:
 *                      type: string
 *                  gender:
 *                      type: string
 *      responses:
 *          200:
 *             description: A json containing a the details of the QrCode of Patient
 *             schema:
 *                  type: object
 *                  properties:
 *                          message:
 *                              type: string
 *                          result:
 *                              type: object
 *                              properties:
 *                                  account:
 *                                      type: string
 *                                  hash:
 *                                      type: string
 *          
 */
router.post('/create',auth, (req, res, next) => {
    try {
        const { error } = patientSchema.validate(req.body);
        if (error) {
            logger.log('error',`Create Patient API error ${JSON.stringify(req.body)} , error : ${error}`);
            return res.status(400).json({ error: error.details[0].message });
        }
        console.log("CREATE PATIENT API CALLED", req.body);
        const patientQrCode = makeQrCode(16);
        console.log(patientQrCode);
        createPatient(req.body.name, req.body.phno, req.body.email, patientQrCode, req.body.dob, req.body.gender).then((account) => {
            console.log("ACCOUNT PAT : ", account);
            QRCode.toDataURL(account.account,{scale:10}, function (err, url) {
                console.log(url);
                sendMail("PATIENT ","This is the QR Code for the you to show to the doctor for accessing your Prescription history and also Booking appointments",req.body.email,url).then((info,err) =>{
                    if(err){
                        logger.log('error',`Create Patient API MAIL error ${JSON.stringify(account)} , error : ${err}`);
                        console.log("err",err," info ",info);
                        return res.status(400).json({ message: "Patient added! But QrCode Not Mailed", result: account });
                    }
                    else{
                        logger.log('info',`Created Patient ${JSON.stringify(req.body)} , patient : ${JSON.stringify(account)}`);
                        return res.status(200).json({ message: "patient added!", result: account });
                    }
                });
              });
            
        });
    }
    catch (e) {
        logger.log('error',`Patient Details API error ${JSON.stringify(req.body)} , error: ${e}`);
        res.status(400).json({ message: "Wrong details!" });
    }

});


/**
 * @swagger
 * /api/patient/details:
 *   post:
 *      tags:
 *          - patient
 *      description: to get the details of a patient
 *      consumes:
 *       - application/json
 *      parameters:
 *       - name: auth-token
 *         description: auth token got from  login.
 *         in: header
 *         type: string
 *       - in: body
 *         name: doctor
 *         schema :
 *              type: object
 *              required:
 *                  - patientQrCode
 *                  - address
 *              properties:
 *                  patientQrCode:
 *                      type: string
 *                  address:
 *                      type: string
 *      responses:
 *          200:
 *             description: A Patient exist and the details of the Patient are returned 
 *             schema:
 *                  type: object
 *                  properties:
 *                          patient:
 *                              type: object
 *                              properties:
 *                                  name:
 *                                      type: string
 *                                  id:
 *                                      type: string
 *                                  email:
 *                                      type: string
 *                                  phone:
 *                                      type: string
 *                                  doctorsVisitedCount:
 *                                      type: string
 *                                  dob:
 *                                      type: string
 *                                  gender:
 *                                      type: string
 *                                  prescriptions:
 *                                      type: array
 *                                      items:
 *                                          $ref: "#/definitions/Prescription"
 *          401: 
 *             description: A Patient exist but doctor doesnt have access to it
 *             schema:
 *                  type: object
 *                  properties:
 *                          OTP:
 *                              type: string 
 * definitions:
 *          Prescription:
 *            type: object
 *            properties:
 *              prescriptionId:
 *                  type: string
 *              medicines:
 *                  type: string
 *              symptoms:
 *                  type: string
 *              diagnosis:
 *                  type: string   
 *              advice:
 *                  type: string
 *              date:
 *                  type: string
 *              doctorName:
 *                  type: string
 */
router.post('/details',auth,(req, res, next) => {
    try {
        const { error } = patientDetailSchema.validate(req.body);
        if (error) {
            logger.log('error',`Patient Details API error ${JSON.stringify(req.body)} , error: ${error}`);
            return res.status(400).json({ error: error.details[0].message });
        }
        console.log("GET PAT : ", req.body);
        getPatient(req.body.patientQrCode, req.body.address).then(async(patient) => {
            console.log("PAT : ", patient);
            if (patient[1] === "null") {
                logger.log('error',`Patient NOT FOUND ${JSON.stringify(req.body)}`);
                res.status(404).json({ patient: "not found" });
            }
            else if (patient[1] === "newDoctor") {
                const OTP = makeOTP(6);
                console.log("OTP FOR PAT : ", req.body.patientQrCode, " is : ", OTP, "SEND TO : ", patient[3]);
                sendOTP(patient[3], OTP).then(() => {
                    logger.log('info',`Patient Details API OTP SENT ${JSON.stringify(req.body)} , OTP : ${OTP}`);
                    res.status(401).json({ OTP: OTP });
                });
            }
            else {
                let responseJson = {name:patient["1"], id:patient["0"], email:patient["2"], phone:patient["3"], doctorsVisitedCount:patient["4"], prescriptions:[], dob:patient["7"], gender:patient["8"]}
                if(patient["6"]){
                    for(let i=0;i<parseInt(patient["6"]);i++){
                        await getPrescription(patient["5"][i], req.body.patientQrCode, req.body.address).then((prescription) => {
                            responseJson.prescriptions.push(prescription);
                        });
                    }
                }
                logger.log('info',`Patient Details SENT ${JSON.stringify(responseJson)}`);
                return res.status(200).json({ patient: responseJson });
            }
        })
    } catch (e) {
        logger.log('error',`Patient Details API error ${JSON.stringify(req.body)} , error: ${e}`);
        res.status(400).json({ message: "ERROR", eror: e });
    }
});


module.exports = router;