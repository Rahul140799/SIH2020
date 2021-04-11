const express = require('express');
const router = express();
const { createPrescription,getPrescription,getPatientForAdmin, getDoctor,giveDoctorAccessToPatientRecords,checkPermission } = require("../Blockchain/connection/handlers.js");
const { prescriptionSchema,getPrescrtiptionSchema,patientDetailSchema } = require('./patient_schema');
const { auth } = require('../../middleware/auth.js');
const { sendPrescription } = require('../../middleware/sendPrescription.js');
const logger = require('../../../config/logger.js')(module);



/**
 * @swagger
 * /api/patient/prescription/create:
 *   post:
 *      tags:
 *          - patient
 *      description: to create a new prescription of the doctor
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
 *             type: object
 *             required: 
 *                  - medicines
 *                  - symptoms
 *                  - diagnosis
 *                  - advice
 *                  - patientQrCode
 *                  - doctorAddress
 *             properties:
 *                  medicines:
 *                      type: string
 *                  symptoms:
 *                      type: string
 *                  diagnosis:
 *                      type: string
 *                  advice:
 *                      type: string
 *                  patientQrCode:
 *                      type: string
 *                  doctorAddress:
 *                      type: string
 *      responses:
 *          200:
 *             description: A doctor exist and the details of the doctor are returned 
 *             schema:
 *                  type: object
 *                  properties:
 *                          hash:
 *                              type: string                        
 * 
 * 
 * 
 *           
 */
router.post('/create',auth,async (req,res,next) => {
    try{
        const { error } = prescriptionSchema.validate(req.body);
        if(error) { 
            logger.log('error',`Patient Create Prescription API error ${JSON.stringify(req.body)}, error: ${error.details[0].message}`);
            return res.status(400).json({ error:error.details[0].message });
        }
        console.log("PRESCEIPTOIN API");
        return await checkPermission(req.body.patientQrCode,req.body.doctorAddress).then(async(flag) => {
            console.log("FLAG : ",flag);
            logger.log('info',`Patient Create Prescription API  ${JSON.stringify(req.body)}, flag : ${flag.toString()}`);
            if(flag === "granted" ){
                return await createPrescription(req.body.medicines, req.body.symptoms, req.body.diagnosis, req.body.advice, req.body.patientQrCode, req.body.doctorAddress).then((result) => {
                    console.log("RESULT : ",result);
                    getPatientForAdmin(req.body.patientQrCode).then((patient) => {
                        getDoctor(req.body.doctorAddress).then((doctor) => {
                            sendPrescription(patient.email,patient.name,req.body.medicines, req.body.symptoms, req.body.diagnosis, req.body.advice, doctor["1"], doctor["2"], doctor["3"], result.prescriptionName, req.body.patientQrCode, patient.phone).then((info,err) => {
                                if(err){
                                    logger.log('err',`Patient Create Prescription API error  ${JSON.stringify(req.body)}, flag : ${flag.toString()}, error : ${err}`);
                                    console.log("err",err);
                                    return res.status(400).json({message:"Presceiption Created! Not Mailed",result:result});
                                }
                                else{
                                    console.log("err",err,"info ",info);
                                    logger.log('info',`Patient Create Prescription API called and created  ${JSON.stringify(result)}`);
                                    return res.status(200).json({message:"Presceiption Created!",result:result});
                                }
                            })
                        });
                    });
                });
            }
            else{
                logger.log('info',`Patient Create Prescription API called VERIFY OTP  ${JSON.stringify(result)}`);
                res.status(401).json({message:"PLEASE VERIFY OTP"});
            }
        });
    }
    catch(e){
        logger.log('error',`Patient Create Prescription API error ${JSON.stringify(req.body)}, error: ${e}`);
        res.status(400).json({error:e});
    }
});







/**
 * @swagger
 * /api/patient/prescription/access:
 *   post:
 *      tags:
 *          - patient
 *      description: to get access for the prescription of the patient
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
 *             type: object
 *             required:
 *                  - patientQrCode
 *                  - address
 *             properties:
 *                  patientQrCode:
 *                      type: string
 *                  address:
 *                      type: string
 *      responses:
 *          200:
 *             description: The doctor is given the access for the patient's records
 *             schema:
 *                  type: object
 *                  properties:
 *                          hash:
 *                              type: string
 *                          access:
 *                              type: string                     
 * 
 * 
 * 
 *           
 */
router.post('/access',auth,async (req,res,next) => {
    try{
        const { error } = patientDetailSchema.validate(req.body);
        if(error) { 
            logger.log('error',`Paitent allow access to Doctor Failed ${JSON.stringify(req.body)}, error: ${error.details[0].message}`);
            return res.status(400).json({ error:error.details[0].message });
        }
        console.log("PRESCEIPTOIN REQUEST API");
        return await giveDoctorAccessToPatientRecords(req.body.patientQrCode, req.body.address).then((result) => {
            logger.log('info',` Doctor is given access to Patient ${JSON.stringify(req.body)}, hash : ${JSON.stringify(result)}`);
            res.status(200).json(result);
        })
    }
    catch(e){
        logger.log('error',`Doctor Grant Access Failed ${JSON.stringify(req.body)} , error: ${e}`);
        res.status(400).json({error:e});
    }
});




/**
 * @swagger
 * /api/patient/prescription/get:
 *   post:
 *      tags:
 *          - patient
 *      description: to get a single prescription of a patient
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
 *                  - prescriptionId
 *                  - patientQrCode
 *                  - doctorAddress
 *              properties:
 *                  prescriptionId:
 *                      type: string
 *                  patientQrCode:
 *                      type: string
 *                  doctorAddress:
 *                      type: string
 *      responses:
 *          200:
 *             description: Prescription details
 *             schema:
 *                 $ref: "#/definitions/Prescription" 
 * 
 * 
 *           
 */
router.post('/get',auth,async(req,res,next) => {
    try{
        const { error } = getPrescrtiptionSchema.validate(req.body);
        if(error) { 
            logger.log('error',`Get Prescription API  error  ${req.body} , error: ${error.details[0].message}`);
            return res.status(400).json({ error:error.details[0].message });
        }
        console.log("GET PRESCRIPTION !");
        return await getPrescription(req.body.prescriptionId, req.body.patientQrCode, req.body.doctorAddress).then((prescription) => {
            console.log("PRESCRIPTION : ",prescription);
            logger.log('info',`Get Prescription API called ${req.body}, prescription: ${prescription}`);
            return res.status(200).json(prescription);
        });
        
    }
    catch(e){
        logger.log('error',`Get Prescription API  error  ${req.body} , error: ${e}`);
        res.status(400).json({ error:e });
    }
});



/*
req.body.email,
req.body.name,
req.body.age,
req.body.gender,
req.body.address,
req.body.date,
out,
req.body.phone
{
    "email": "jayvishaalj.01@gmail.com"
    "name":"Ferran",
    "age":"21",
    "gender":"Male",
    "address":"Cee Dee Yes, Velachery, Chennai-60",
    "date":"8-8-2020",
    "phone": "7358125151",
    "out":{
        "result": {
          "medicines": [
            {
              "dosage": "5",
              "duration": "two weeks",
              "form": "tablets",
              "foodtime": "(AF)",
              "frequency": "every morning and night after meal and apply",
              "medicine": "Hydroxychloroquine 20 mg",
              "onone": "1-0-1",
              "route": "",
              "strength": "20 mg"
            },
            {
              "dosage": "20ml",
              "duration": "for the next 7 days",
              "form": "Ointment",
              "foodtime": "",
              "frequency": "every night once a day",
              "medicine": "QC 8 Eye Ointment 20ml",
              "onone": "0-0-1",
              "route": "",
              "strength": ""
            }
          ]
        }
    }
}



*/

router.post('/create/pdf',(req,res,next) => {
    logger.log('info',`Get PDF API called ${req.body}`);
    const prescribed = req.body.out
      arr = []
      out = []

      prescribed.result.medicines.forEach((i) => {
          arr = [i.medicine,i.onone,i.foodtime,i.dosage,i.duration,i.form]
          out.push(arr)
      })
    console.log("Length",out);
    sendPrescription(req.body.email,req.body.name,req.body.age,req.body.gender,req.body.address,req.body.date,out,req.body.phone);
    
    console.log(req.body);
    res.status(200).json({
        "message" : "success"
    });
});

module.exports = router;