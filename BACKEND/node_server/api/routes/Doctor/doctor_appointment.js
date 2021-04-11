const express = require('express');
const router = express();
const mongoose = require('mongoose');
const { appointmentSchema,appointmentSchemaCheck }  = require('./doctor_schema');
const { auth } = require('../../middleware/auth');
const { checkPermission,getPatientForAdmin, getDoctor } = require('../Blockchain/connection/handlers');
const logger = require('../../../config/logger')(module);


/**
 * @swagger
 * /api/doctor/appointment/create:
 *   post:
 *      tags:
 *          - doctor
 *      description: to create an appointment for a patient to visit the doctor
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
 *                  - time
 *                  - date
 *                  - patientQrCode
 *                  - doctorAddress
 *             properties:
 *                  time:
 *                      type: string
 *                      format: HH:MM:SS
 *                  date:
 *                      type: string
 *                      format: YYYY-MM-DD
 *                  patientQrCode:
 *                      type: string
 *                  doctorAddress:
 *                      type: string
 *      responses:
 *          200:
 *             description: The appointment is successfully added 
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
router.post('/create', auth ,(req,res,next) => {
    try {
        const { error } = appointmentSchemaCheck.validate(req.body);
        if(error) {
            logger.log('error',`Doctor Appointment create error ${JSON.stringify(req.body)} error : ${error.details[0].message}`);
            return res.status(400).json({ error:error.details[0].message });
        }
        appointmentSchema.countDocuments({},(err,count) =>{
            console.log(count);
            const appointment = new appointmentSchema({
                _id : mongoose.Types.ObjectId(),
                doctorAddress : req.body.doctorAddress,
                patientQrCode : req.body.patientQrCode,
                appointmentNumber : count+1,
                time : req.body.time,
                date:  req.body.date,
                questions: [],
                answers: [],
                visited : false,
                answered : false,
                dateToAsk : undefined
            });
            appointment.save().then((result)=>{
                console.log("RESULT "+result);
                logger.log('info',`Doctor Appointment created ${JSON.stringify(req.body)}`);
                return res.status(200).json({
                    message: "sucessfully added!",
                });
            }).catch((err)=>{
                console.log("ERROR "+err);
                logger.log('error',`Doctor Appointment create error ${JSON.stringify(req.body)} error : ${err}`);
                res.status(500).json({
                    message : err
                });
            });
        });
    } catch (error) {
        logger.log('error',`Doctor Appointment create error ${JSON.stringify(req.body)} error : ${error}`);
        res.status(500).json({
            message : error
        });
    }
});




/**
 * @swagger
 * /api/doctor/appointment/get:
 *   post:
 *      tags:
 *          - doctor
 *      description: to get all appointments of a doctor
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
 *             description: all the appointments of a doctor is displayed 
 *             schema:
 *                  type: array
 *                  items:
 *                      type: object
 *                      properties:
 *                          appointment:
 *                              $ref: "#/definitions/appointment"
 *                          patientDetails:
 *                              type: object
 *                              properties:
 *                                  name:
 *                                      type: string
 *                                  phno:
 *                                      type: string
 *                                  patientId:
 *                                      type: string
 *                                  email:
 *                                      type: string
 *                          doctorDetials:
 *                              type: object
 *                              properties:
 *                                  name:
 *                                      type: string
 *                                  phno:
 *                                      type: string
 *                                  doctorId:
 *                                      type: string
 *                                  email:
 *                                      type: string    
 *
 * definitions:
 *          appointment:
 *            type: object
 *            properties:
 *              _id:
 *                  type: string
 *              doctorAddress:
 *                  type: string
 *              patientQrCode:
 *                  type: string
 *              appointmentNumber:
 *                  type: number   
 *              time:
 *                  type: string
 *                  format: HH:MM:SS
 *              date:
 *                  type: string
 *                  pattern: YYYY-MM-DD
 *              visited:
 *                  type: boolean
 *              questions:
 *                  type: array
 *                  items:
 *                      type: string
 *              answers:
 *                  type: array
 *                  items:
 *                      type: string
 *              answered:
 *                  type: boolean
 *              dateToAsk:
 *                  type: string
 *                  pattern: YYYY-MM-DD
 * 
 *           
 */
router.post('/get', auth, (req,res,next) => {
    try {
        if(req.body.doctorAddress) { 
            appointmentSchema.find({ "doctorAddress": req.body.doctorAddress }, async (err,appointments) => {
                if(err){
                    logger.log('error',`Doctor Appointment  Details API error ${JSON.stringify(req.body)} , error: ${err}`);
                    res.status(400).json({ error:err });
                }
                else
                {
                    let jsonRes = [];
                    for(var i=0;i<appointments.length;i++){
                        await getPatientForAdmin(appointments[i].patientQrCode).then(async (patientDetails) => {
                            await getDoctor(appointments[i].doctorAddress).then((doctor) => {
                                jsonRes.push({appointment:appointments[i], patientDetails:patientDetails, doctorDetials:{ "name": doctor["1"], "phno": doctor["2"], "doctorId": doctor["0"], "email": doctor["3"] }});
                            });
                        });
                    }
                    logger.log('info',`Doctor Appointment Details ALL API called ${JSON.stringify(req.body)} , appointment: ${JSON.stringify(jsonRes)}`);
                    res.status(200).json(jsonRes);
                }
            });
        }
        else{
            logger.log('error',`Doctor Appointment Details ALL API error ${JSON.stringify(req.body)} , error :  Doctor address not specified `);
            return res.status(400).json({ error:"specify the doctor address" });
        }
    } catch (error) {
        logger.log('error',`Doctor Appointment Details ALL API error ${JSON.stringify(req.body)} , error :  ${error}`);
        res.status(500).json({
            message : error
        });
    }
});


/**
 * @swagger
 * /api/doctor/appointment/date:
 *   post:
 *      tags:
 *          - doctor
 *      description: to get all appointments of a doctor on a given date
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
 *                  - date
 *             properties:
 *                  doctorAddress:
 *                      type: string
 *                  date:
 *                      type: string
 *                      pattern: YYYY-MM-DD
 *      responses:
 *          200:
 *             description: all the appointments of a doctor is displayed 
 *             schema:
 *                  type: array
 *                  items:
 *                      type: object
 *                      properties:
 *                          appointment:
 *                              $ref: "#/definitions/appointment"
 *                          patientDetails:
 *                              type: object
 *                              properties:
 *                                  name:
 *                                      type: string
 *                                  phno:
 *                                      type: string
 *                                  patientId:
 *                                      type: string
 *                                  email:
 *                                      type: string
 *                          isNewPatient:
 *                              type: boolean       
 *                          appointmentTime:
 *                              type: string
 * 
 *           
 */
router.post('/date', auth, (req,res,next) => {
    try {
        if(req.body.doctorAddress) { 
            appointmentSchema.find({ "doctorAddress": req.body.doctorAddress, "date": req.body.date },async(err,appointments) => {
                if(err){
                    logger.log('error',`Doctor Appointment  Details API error ${JSON.stringify(req.body)} , error: ${err}`);
                    res.status(400).json({ error:err });
                }
                else
                {
                    let jsonRes = [];
                    for(var i=0;i<appointments.length;i++){
                        await getPatientForAdmin(appointments[i].patientQrCode).then(async (patientDetails) => {
                            await checkPermission(appointments[i].patientQrCode, appointments[i].doctorAddress).then((access) => {
                                if(access === "granted"){
                                    jsonRes.push({appointment:appointments[i], patientDetails:patientDetails, isNewPatient: false,appointmentTime: appointments[i]['date']+'T'+appointments[i]['time']+'Z' });
                                }
                                else if(access === "newDoc"){
                                    jsonRes.push({appointment:appointments[i], patientDetails:patientDetails, isNewPatient: true,appointmentTime: appointments[i]['date']+'T'+appointments[i]['time']+'Z' });
                                }
                            })
                        });
                    }
                    logger.log('info',`Doctor Appointment Details API called ${JSON.stringify(req.body)} , appointment: ${JSON.stringify(jsonRes)}`);
                    res.status(200).json(jsonRes);
                }
            });
        }
        else{
            logger.log('error',`Doctor Appointment Details API error ${JSON.stringify(req.body)} , error :  Doctor address not specified `);
            return res.status(400).json({ error:"specify the doctor address" });
        }
    } catch (error) {
        logger.log('error',`Doctor Appointment Details API error ${JSON.stringify(req.body)} , error :  ${error}`);
        res.status(500).json({
            message : error
        });
    }
});


/**
 * @swagger
 * /api/doctor/appointment/visited:
 *   put:
 *      tags:
 *          - doctor
 *      description: to make an appointment Visited
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
 *             properties:
 *                  appointmentNumber:
 *                      type: number
 *      responses:
 *          200:
 *             description: The Appointment is updated
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
router.put('/visited', auth, (req,res,next) => {
    try{
        if(req.body.appointmentNumber){
            appointmentSchema.updateOne({"appointmentNumber" : req.body.appointmentNumber},{"visited":true},(err,appointment) => {
                logger.log('info',`Appointment Visited ${JSON.stringify(req.body)}`);
                res.status(200).json({message:'appointment updated'});
            });
        }
        else{
            logger.log('error',`Appointment Visited API ERROR ${JSON.stringify(req.body)}, error : Appointment Number not specified`);
            res.status(400).json({message:"Appointment Number not specified"});
        }
    }
    catch(e){
        logger.log('error',`Appointment Visited API ERROR ${JSON.stringify(req.body)}, error : ${e}`);
            res.status(500).json({error: e});
    }
});


module.exports = router;