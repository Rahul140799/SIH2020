const express = require('express');
const router = express();
const { getPatientForAdmin } = require("../Blockchain/connection/handlers.js");
const { auth } = require('../../middleware/auth.js');
const logger = require('../../../config/logger')(module);

/**
 * @swagger
 * /api/admin/patient/details:
 *   post:
 *      tags:
 *          - admin
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
 *              properties:
 *                  patientQrCode:
 *                      type: string
 *      responses:
 *          200:
 *             description: A doctor exist and the details of the doctor are returned 
 *             schema:
 *                  type: object
 *                  properties:
 *                          patient:
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
 */
router.post('/details',auth,(req,res,next)=> {
    try{
        console.log("GET PAT : ",req.body);
        if(req.body.patientQrCode === undefined){
            res.status(400).json({message:"Bad Request"});
        }
        else{
            getPatientForAdmin(req.body.patientQrCode).then((patient) => {
                console.log("PAT : ",patient);
                logger.log('info',`Admin Call Patient Details API  ${JSON.stringify(req.body)}, patient: ${JSON.stringify(patient)}`);
                res.status(200).json({patient:patient});
            });
        }
    }
    catch(e){
        logger.log('error',`ADMIN Patient Details API error ${JSON.stringify(req.body)} , error: ${e}`);
        res.status(400).json({message:"Bad Request"});
    }
    
});


module.exports = router;