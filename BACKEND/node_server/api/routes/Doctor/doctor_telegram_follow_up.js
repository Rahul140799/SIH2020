const express = require('express');
const router = express();
const mongoose = require('mongoose');
const { appointmentSchema, addQuestionSchema, getAnswerSchema }  = require('./doctor_schema');
const { auth } = require('../../middleware/auth');
const logger = require('../../../config/logger')(module);
const { getPatientForAdmin } = require('../Blockchain/connection/handlers');


/**
 * @swagger
 * /api/doctor/followup/add:
 *   post:
 *      tags:
 *          - doctor
 *      description: to add follow up questions to be asked by the telegram bot to the patients
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
 *                  - appointmentNumber
 *                  - questions
 *                  - date
 *             properties:
 *                  appointmentNumber:
 *                      type: number
 *                  questions:
 *                      type: array
 *                      items:
 *                          type: string
 *                  dateToAsk:
 *                      type: string
 *                      pattern: YYYY-MM-DD
 *      responses:
 *          200:
 *             description: The Follow up is successfully added 
 *             schema:
 *                  type: object
 *                  properties:
 *                          message:
 *                              type: string                        
 * 
 * 
 * 
 *           
 */
router.post('/add', auth ,async (req,res,next) => {
    try {
        const { error } = addQuestionSchema.validate(req.body);
        if(error) {
            logger.log('error',`Doctor Appointment Question ADD API error ${JSON.stringify(req.body)} error : ${error.details[0].message}`);
            return res.status(400).json({ error:error.details[0].message });
        }
        appointmentSchema.updateOne(
            {'appointmentNumber' : req.body.appointmentNumber},
            {"questions" : req.body.questions, "dateToAsk" : req.body.dateToAsk},
            (err,raw) => {
                if(err){
                    logger.log('error',`Doctor Appointment Question Add API error ${JSON.stringify(req.body)}, error: ${err} `);
                    return res.status(400).json({ error : err});
                }
                logger.log('info',` Doctor Appointment Questions Added ${JSON.stringify(req.body)}, response : ${JSON.stringify(raw)}`);
                return res.status(200).json({message:"updated Questions"});
            }
        )
    } catch (e) {
        logger.log('error',`Doctor Appointment Question Add API error ${JSON.stringify(req.body)}, error: ${e} `);
        return res.status(500).json({ error : e});
    }
});


/**
 * @swagger
 * /api/doctor/followup/all:
 *   post:
 *      tags:
 *          - doctor
 *      description: to get follow up questions that are answered by the patients for the respective doctor's follow up question
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
 *                  - doctorAddress
 *             properties:
 *                  doctorAddress:
 *                      type: string
 *      responses:
 *          200:
 *             description: All the Follow up realted to this doctor which are answered are sent back
 *             schema:
 *                  type: array
 *                  items:
 *                      type: object
 *                      properties:
 *                          patientName:
 *                              type: string
 *                          patientEmail:
 *                              type: string                        
 *                          patientPhone:
 *                              type: string
 *                          questions:
 *                              type: array
 *                              items:
 *                                  type: string
 *                          answers:
 *                              type: array
 *                              items:
 *                                  type: string
 *                          appointmentNumber:
 *                              type: string
 *                          dateToAsk:
 *                              type: string
 *                              pattern: YYYY-MM-DD
 * 
 *           
 */
router.post('/all', auth, async(req,res,next) => {
    try {
        if(req.body.doctorAddress){
            appointmentSchema.find({"doctorAddress":req.body.doctorAddress, "answered": true, "visited": true},async(err,appointments) => {
                console.log("appointments :",appointments);
                let jsonRes = [];
                for(var i=0;i<appointments.length;i++){
                    await getPatientForAdmin(appointments[i].patientQrCode).then((patientDetails) => {
                        jsonRes.push({ patientName : patientDetails.name, patientEmail : patientDetails.email, patientPhone : patientDetails.phone, questions: appointments[i].questions, answers : appointments[i].answers, appointmentNumber : appointments[i].appointmentNumber});
                    });
                }
                logger.log('info',`Doctor Appointments All for ${JSON.stringify(req.body)} got ${JSON.stringify(jsonRes)}`);
                return res.status(200).json(jsonRes);
            })
        }
        else{
            logger.log('error',`Doctor Appointment GET ALL ANSWERS API error ${JSON.stringify(req.body)} error : Doctor Address is not present`);
            return res.status(400).json({ error:"Doctor Address is not present" });
        }
    } catch (e) {
        logger.log('error',`Doctor Appointment GET ALL ANSWERS API error ${JSON.stringify(req.body)} error : ${e}`);
            return res.status(500).json({ error: e });
    }
});

/**
 * @swagger
 * /api/doctor/followup/get:
 *   post:
 *      tags:
 *          - doctor
 *      description: to get follow up questions and Answers related to the respective doctor and patient this gives the result even if the patient didn't answer the questions
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
 *                  - doctorAddress
 *                  - patientQrCode
 *             properties:
 *                  doctorAddress:
 *                      type: string
 *                  patientQrCode:
 *                      type: string
 *      responses:
 *          200:
 *             description: All the Follow up realted to this doctor and patient are displayed
 *             schema:
 *                  type: array
 *                  items:
 *                      type: object
 *                      properties:
 *                          time:
 *                              type: string
 *                          questions:
 *                              type: array
 *                              items:
 *                                  type: string
 *                          answers:
 *                              type: array
 *                              items:
 *                                  type: string
 *                          appointmentNumber:
 *                              type: string
 * 
 *           
 */
router.post('/get', auth, async(req,res,next) => {
    try {
        if(req.body.doctorAddress){
            appointmentSchema.find({"doctorAddress":req.body.doctorAddress, "patientQrCode": req.body.patientQrCode, "visited": true},' appointmentNumber time questions answers',async(err,appointments) => {
                console.log("appointments :",appointments);
                logger.log('info',`Doctor Appointments GET ONE PATIENT for ${JSON.stringify(req.body)} got ${JSON.stringify(appointments)}`);
                return res.status(200).json(appointments);
            })
        }
        else{
            logger.log('error',`Doctor Appointment GET ONE PATIENT API error ${JSON.stringify(req.body)} error : Doctor Address is not present`);
            return res.status(400).json({ error:"Doctor Address is not present" });
        }
    } catch (e) {
        logger.log('error',`Doctor Appointment GET ONE PATIENT API error ${JSON.stringify(req.body)} error : ${e}`);
            return res.status(500).json({ error: e });
    }
});


module.exports = router;