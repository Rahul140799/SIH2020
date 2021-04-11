const Joi = require('@hapi/joi');

module.exports.patientSchema = Joi.object({
    name: Joi.string().required(),
    phno: Joi.string().min(10).max(10).required(),
    email: Joi.string().min(6).required().email(),
    dob: Joi.string().required(),
    gender: Joi.string().required(),
});

module.exports.patientDetailSchema = Joi.object({
    patientQrCode: Joi.string().required(),
    address: Joi.string().required()
});

module.exports.prescriptionSchema = Joi.object({
    medicines: Joi.string().required(), 
    symptoms: Joi.string().required(), 
    diagnosis: Joi.string().required(), 
    advice: Joi.string().required(), 
    patientQrCode: Joi.string().required(), 
    doctorAddress: Joi.string().required()
});

module.exports.getPrescrtiptionSchema = Joi.object({
    prescriptionId: Joi.string().required(),
    patientQrCode: Joi.string().required(),
    doctorAddress: Joi.string().required()
});